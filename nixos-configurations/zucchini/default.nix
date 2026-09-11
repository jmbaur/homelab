{
  config,
  pkgs,
  lib,
  ...
}:

let
  # libcamera with the rkisp2 pipeline handler and IPA.
  #
  # The rkisp2 series is not upstream yet, and it sits on top of ~25 other
  # unmerged libcamera commits (the delayed-controls rework, BufferQueue,
  # SequenceSyncHelper and a set of rkisp1 refactors). Carrying all of that as
  # patch files is unwieldy, so pin the source to the author's v3 branch
  # instead and keep only our own patch on top.
  #
  # Branch: epaul/dev/rkisp2/upstream-v3, which is upstream master
  # 94d174420 ("gstreamer: Reconfigure when peer caps gain extra fields")
  # plus 45 commits. Corresponds to the libcamera "[PATCH v3 00/20] Add
  # support for rkisp2" posting of 2026-08-27.
  libcamera = pkgs.libcamera.overrideAttrs (old: {
    version = "0.7.2-unstable-2026-08-27-rkisp2-v3";

    src = pkgs.fetchgit {
      url = "https://git.ideasonboard.com/epaul/libcamera.git";
      rev = "16de359d9b25a841e4b6fdf59d432baadb3c5b07";
      hash = "sha256-SNv5GVa2tIOjZyB1JwG951H1rL7TBi1qXcDWSjIyKig=";
    };

    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.pkgsBuildHost.addDriverRunpath ];
    patches = (old.patches or [ ]) ++ [ ./libcamera-ov13855-tuning.patch ];
  });

  # GStreamer needs the libcamerasrc element from our libcamera, plus the
  # encoder and the RTSP sink.
  gstPlugins = [
    libcamera
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-bad
    pkgs.gst_all_1.gst-plugins-ugly
    pkgs.gst_all_1.gst-rtsp-server
  ];

  # Publishes the camera into mediamtx.
  #
  # This encodes H.264 in software. Mainline registers the RK3588 vepu121 as
  # HANTRO_JPEG_ENCODER, so the only hardware encoder available here does
  # JPEG; the H.264/HEVC block (rkvenc2) has no mainline driver. The
  # resolution and preset below are a guess that has not been measured on the
  # board -- this is the knob to turn if it cannot keep up or runs hot.
  cameraStream = pkgs.writeShellApplication {
    name = "camera-stream";
    runtimeInputs = [ pkgs.gst_all_1.gstreamer ];
    text = ''
      export GST_PLUGIN_SYSTEM_PATH_1_0="${lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPlugins}"

      exec gst-launch-1.0 -q \
        libcamerasrc \
        ! video/x-raw,format=NV12,width=1920,height=1080 \
        ! queue max-size-buffers=2 leaky=downstream \
        ! x264enc tune=zerolatency speed-preset=veryfast bitrate=4000 key-int-max=60 \
        ! h264parse config-interval=-1 \
        ! rtspclientsink location="rtsp://127.0.0.1:8554/''${MTX_PATH:-cam}" protocols=tcp
    '';
  };
in

{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      boot.kernelPackages = pkgs.linuxPackages_7_2;
      boot.kernelPatches =
        lib.mapAttrsToList
          (
            name:
            lib.const {
              name = lib.removeSuffix ".patch" name;
              patch = ./kernel-patches/${name};
            }
          )
          (
            lib.filterAttrs (name: entryType: entryType == "regular" && lib.hasSuffix ".patch" name) (
              lib.readDir ./kernel-patches
            )
          )
        ++ [
          {
            name = "rkisp2-camera-config";
            patch = null;
            structuredExtraConfig = with lib.kernel; {
              V4L_PLATFORM_DRIVERS = yes;
              # sensor -> csi_dphy0 -> csi2 -> vicap -> (userspace) -> isp0
              PHY_ROCKCHIP_INNO_CSIDPHY = module;
              VIDEO_DW_MIPI_CSI2RX = module;
              VIDEO_ROCKCHIP_CIF = module;
              VIDEO_ROCKCHIP_ISP2 = module;
              VIDEO_OV13855 = module;
              VIDEO_DW9714 = module; # lens voice coil motor
            };
          }
        ];

      boot.initrd.availableKernelModules = [
        "dwmac_rk"
        "nvme"
        "phy-rockchip-naneng-combphy"
        "rtc_hym8563"
      ];

      hardware.deviceTree = {
        name = "rockchip/rk3588s-orangepi-5.dtb";
        overlays = [
          {
            name = "use-standard-baudrate";
            dtsText = ''
              /dts-v1/;
              /plugin/;

              / {
                compatible = "rockchip,rk3588s";
              };

              &{/chosen} {
                stdout-path = "serial2:115200n8";
              };
            '';
          }
          {
            name = baseNameOf ./rk3588-ov13855-c1.dtso;
            dtsFile = ./rk3588-ov13855-c1.dtso;
          }
        ];
      };

      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem pkg.pname [ "rkbin" ];
      system.build.firmware = pkgs.makeUBoot {
        boardName = "orangepi-5-rk3588s";
        artifacts = [ "u-boot-rockchip-spi.bin" ];
        makeFlags = [
          "BL31=${pkgs.armTrustedFirmwareRK3588}/bl31.elf"
          "ROCKCHIP_TPL=${pkgs.rkbin.TPL_RK3588}"
        ];
        meta.platforms = [ "aarch64-linux" ];
        kconfig = with lib.kernel; {
          BAUDRATE = freeform 115200; # c'mon rockchip
          USE_PREBOOT = yes;
          PREBOOT = freeform "pci enum; usb start; nvme scan";
        };
      };

      hardware.graphics.enable = true;

      services.mediamtx = {
        enable = true;
        allowVideoAccess = true;
        settings = {
          paths.cam = {
            # Only run the encoder while something is actually watching.
            runOnDemand = lib.getExe cameraStream;
            runOnDemandRestart = true;
            runOnDemandCloseAfter = "10s";
          };
        };
      };

      environment.systemPackages = [
        libcamera
        cameraStream
        pkgs.ffmpeg-headless
        pkgs.gpio-utils
        pkgs.i2c-tools
        pkgs.libgpiod
        pkgs.mediamtx
        pkgs.mtdutils
        pkgs.uboot-env-tools
        pkgs.v4l-utils
        (pkgs.writeShellScriptBin "update-firmware" ''
          ${lib.getExe' pkgs.mtdutils "flashcp"} \
            --verbose \
            ${config.system.build.firmware}/u-boot-rockchip-spi.bin \
            /dev/mtd0
        '')
      ];

      hardware.firmware = [
        (pkgs.extractLinuxFirmwareDirectory "arm/mali")
      ];

      # vulkan doesn't work (yet)
      environment.variables.GSK_RENDERER = "gl";

      services.evremap.enable = false;
    }
    {
      custom.basicNetwork.enable = true;
      custom.normalUser.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";
    }
  ];
}
