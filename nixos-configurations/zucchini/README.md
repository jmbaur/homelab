# zucchini camera stack

OV13855 on the **CAM1** connector, through the Rockchip ISP (rkisp2), exposed
over RTSP by mediamtx.

Nothing here has been run on the board. It cross-compiles, the device tree
overlay applies to the real base DTB, and libcamera builds with the rkisp2
pipeline handler and IPA — but the pipeline has never been streamed.

## The camera must be on CAM1

Not CAM2 or CAM3. The Orange Pi 5 wires its three camera connectors like this
(from the vendor `rk3588s-orangepi-5-camera{1,2,3}.dtsi`):

| Connector | PHY | CSI-2 host | Mainline |
|---|---|---|---|
| CAM1 | `csi2_dphy0`, plain D-PHY | `mipi2_csi2` @ `0xfdd30000` | `csi2` + `csi_dphy0` |
| CAM2 | `csi2_dcphy0`, DC-PHY | `mipi0_csi2` @ `0xfdd10000` | unsupported |
| CAM3 | `csi2_dcphy1`, DC-PHY | `mipi1_csi2` @ `0xfdd20000` | unsupported |

CAM2 and CAM3 hang off the Samsung DC-PHYs. Mainline's
`phy-rockchip-samsung-dcphy` only drives those for DSI output — there is no
receive support — and `rk3588-base.dtsi` has no CSI host node for
`0xfdd10000` or `0xfdd20000` either. Using them would mean writing CSI-RX
support into that PHY driver first.

## Layout

- `kernel-patches/` — 13 patches against linux 7.2.4, applied via
  `boot.kernelPatches`.
  - `0001`–`0006`: V4L2 extensible statistics. Not in mainline 7.2.4, and the
    rkisp2 stats patch does not compile without them.
  - `0007`–`0011`: the rkisp2 driver itself, from the kernel "[PATCH v3]"
    posting.
  - `0012`: the Rockchip OV13855 sensor driver.
  - `0013`: adds the missing `select V4L2_ISP` to rkisp2's Kconfig. Without
    it `rockchip-isp2.ko` builds but will not load.
- `rk3588-ov13855-c1.dtso` — enables the sensor, `csi_dphy0`, `csi2`, VICAP
  and ISP0.
- `libcamera-ov13855-tuning.patch` — our only libcamera patch. libcamera's
  `src` is pinned in `default.nix` to the rkisp2 v3 branch rather than
  carrying the other 45 commits as files.

## Checking it on the board

The ISP runs memory-to-memory: VICAP captures raw frames, userspace hands
them back to the ISP through `rkisp2_rawrd0`. So there are two media devices
and no device tree link between them.

```sh
# Sensor probed on i2c7?
dmesg | grep -iE 'ov13855|rkisp2|rkcif|csi2'

# Two media devices: "rockchip-cif" and "rkisp2"
media-ctl -p -d /dev/media0
media-ctl -p -d /dev/media1

# libcamera should list exactly one camera
cam -l

# Grab a few frames without mediamtx in the way
cam -c1 --capture=10
```

The pipeline handler looks for these names, so if `cam -l` finds nothing this
is the first thing to check:
`dw-mipi-csi2rx fdd30000.csi`, `rkcif-mipi2`, `rkcif-mipi2-id0`, and on the
ISP side `rkisp2_isp`, `rkisp2_rawrd0`, `rkisp2_mainpath`.

The stream is at `rtsp://zucchini:8554/cam`, encoded on demand and shut down
10s after the last viewer disconnects.

## Known rough edges

- **H.264 is encoded in software.** Mainline registers the RK3588 `vepu121`
  as `HANTRO_JPEG_ENCODER`; the H.264/HEVC block (rkvenc2) has no mainline
  driver. Drop the resolution in `default.nix` if the board runs hot.
- **The tuning file is a starting point, not a calibration.** No colour
  correction matrix and no lens shading correction — expect undersaturated
  colour and corner vignetting. `utils/tuning/rkisp2.py` in the libcamera
  tree generates real ones from captures.
- **Pixel rate is wrong by 2x.** The sensor driver hardcodes
  `OV13855_LANES 4` when computing `V4L2_CID_PIXEL_RATE`, but the module is
  wired with 2 lanes. Exposure and frame-duration maths inherit that error.
- **No autofocus.** The rkisp2 IPA has no AF algorithm. The VCM is exposed as
  a subdev; set focus by hand with `V4L2_CID_FOCUS_ABSOLUTE`.
