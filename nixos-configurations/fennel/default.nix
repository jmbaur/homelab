{
  config,
  lib,
  pkgs,
  ...
}:
{
  # cuda (on jetspn) does not currently cross-compile
  nixpkgs.buildPlatform = "aarch64-linux";

  nixpkgs.config = {
    allowUnfreePredicate = pkgs._cuda.lib.allowUnfreeCudaPredicate;
    cudaCapabilities = [ "11.0" ];
    cudaForwardCompat = true;
    cudaSupport = true;
  };

  hardware.nvidia-jetpack = {
    enable = true;
    majorVersion = "7";
    som = "thor-agx";
    carrierBoard = "devkit";
  };

  boot.kernelPatches = [
    {
      name = "erofs";
      patch = null;
      structuredExtraConfig = {
        EROFS_FS = lib.kernel.yes;
      };
    }
  ];

  hardware.graphics.enable = true;

  users.users.root.initialPassword = "";

  boot.initrd.includeDefaultModules = false;

  # TODO(jared): be more specific
  custom.recovery.targetDisk = "/dev/nvme0n1";

  custom.yggdrasil.peers.celery.allowedTCPPorts = [ config.services.llama-cpp.settings.port ];

  environment.systemPackages = [
    config.services.llama-cpp.package
    pkgs.python3.pkgs.huggingface-hub
  ];

  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { cudaSupport = true; };
    openFirewall = false;
    settings = {
      port = 8080;
      host = "::";

      # TODO(jared): fill out
      # model = "./Qwen3.8-27B-UD-Q8_K_XL.gguf";
      # gpu-layers = 999;
      # ctx-size = 222144;
      # temp = "1.0";
      # top-p = "0.95";
      # top-k = 20;
      # min-p = "0.0";
      # mmproj = "./Qwen3.8-27B-GGUF/mmproj-BF16.gguf";
      # reasoning = "off";
    };
  };
}
