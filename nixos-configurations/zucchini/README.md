# zucchini camera stack

OV13855 on the **CAM3** connector, through the Rockchip ISP (rkisp2), exposed
over RTSP by mediamtx.

It streams 1080p30 H.264: the sensor runs a 4224x2376 window at 30 fps over
4 lanes, the ISP scales it to 1920x1080 NV12, and x264 encodes it.

## The camera is on CAM3

The Orange Pi 5 wires its three camera connectors like this (from the vendor
`rk3588s-orangepi-5-camera{1,2,3}.dtsi`):

| Connector | I2C | PHY | CSI-2 host | Mainline |
|---|---|---|---|---|
| CAM1 | `i2c7` | `csi2_dphy0`, plain D-PHY | `mipi2_csi2` @ `0xfdd30000` | `csi2` + `csi_dphy0` |
| CAM2 | `i2c7` | `csi2_dcphy0`, DC-PHY | `mipi0_csi2` @ `0xfdd10000` | `csi0` + `mipidcphy0`, with `0014`/`0015` |
| CAM3 | `i2c2` | `csi2_dcphy1`, DC-PHY | `mipi1_csi2` @ `0xfdd20000` | `csi1` + `mipidcphy1`, with `0014`/`0015` |

CAM1 needs no extra patches, but on this board the module gets no power there
(nothing answers on `i2c7`, and the adapter's regulators read ~1.3 V, which is
leakage). On CAM3 the same module, cable and adapter probe fine. Mainline's
`phy-rockchip-samsung-dcphy` only drives the DC-PHYs for DSI output, so
`0014` adds receive support and `0015` adds the `csi0`/`csi1` hosts; both are
from <https://github.com/peyton-howe/ubuntu-image-builder>
(`patches/kernel/mainline/`), which brings up cameras on all three connectors.

`rk3588-ov13855-c1.dtso` is kept for CAM1.

## Layout

- `kernel-patches/` — 24 patches against linux 7.2, applied via
  `boot.kernelPatches`.
  - `0001`–`0006`: V4L2 extensible statistics. Not in mainline 7.2.4, and the
    rkisp2 stats patch does not compile without them.
  - `0007`–`0011`: the rkisp2 driver itself, from the kernel "[PATCH v3]"
    posting.
  - `0012`: the Rockchip OV13855 sensor driver, with its subdev renamed to
    the mainline style (`ov13855 2-0036`), which libcamera takes the model
    name from.
  - `0013`: adds the missing `select V4L2_ISP` to rkisp2's Kconfig. Without
    it `rockchip-isp2.ko` builds but will not load.
  - `0014`–`0015`: DC-PHY CSI receive and the `csi0`/`csi1` hosts, for CAM2
    and CAM3.
  - `0016`: makes rkcif stop a stream at a frame end before stopping the
    source. Mainline does it the other way round, so the frame end never
    comes and the runtime-suspend reset hits the VICAP mid-DMA, which hangs
    the board.
  - `0017`–`0020`: rkisp2 fixes. The raw read moves to the next buffer on
    the ISP frame end rather than the capture path's (which comes early when
    cropping, and stalls the ISP for good on large frames), and stopping waits
    for the read in flight. The resizers default to scaling the full field of
    view instead of cropping the top-left corner, and output 4:2:2 so NV12
    gets chroma for the whole frame.
  - `0021`: rkisp2 acknowledges the stats interrupts when they arrive. They
    share the ISP's interrupt line, and leaving them pending until the frame
    end made the handler run ~20000 times a frame, which pinned a CPU and
    could hang the board.
  - `0022`–`0023`: OV13855 fixes. The horizontal blanking is reported in
    pixels (the HTS register counts in 4s), so libcamera gets the frame
    duration and exposure times right. A 4224x2376 mode is added, because
    one ISP manages only ~26 fps at 4224x3136; libcamera picks the 16:9
    mode for 1080p and gets a full 30 fps.
  - `0024`: rkcif runtime-suspends synchronously when a stream stops. The
    suspend resets the VICAP and its IOMMU, and run asynchronously it raced
    with the buffers being unmapped, which locked up the bus. Killing a
    camera application mid-stream hung the board within a few tries.
- `rk3588-ov13855-c3.dtso` — enables the sensor on CAM3 (all 4 data lanes,
  although the Orange Pi device tree only lists 2), `csi1`, VICAP and
  ISP0.
- `libcamera-ov13855-tuning.patch` — the sensor's tuning file.
- `libcamera-ov13855-sensor-helper.patch` — the sensor's gain model and black
  level, which the IPA needs.
- `libcamera-rkisp2-any-csi-port.patch` — makes the rkisp2 pipeline handler
  find the CSI-2 receiver and VICAP interface from the sensor instead of
  hard-coding CAM1's (`fdd30000`, `rkcif-mipi2`).
- `libcamera-rkisp2-sensor-bayer-order.patch` — makes the rkisp2 pipeline
  handler use the sensor's Bayer order (SBGGR10) instead of assuming SRGGB10,
  which crashes in `clampSensorSize()`. Reported on the list at
  <https://patchwork.libcamera.org/comment/40791/>.
- `libcamera-rkisp2-sensor-timestamp.patch` — reports
  `controls::SensorTimestamp`, as rkisp1 does. Without it libcamerasrc stamps
  every buffer with a bogus PTS and the RTSP stream has no usable timing.
- `libcamera-rkisp2-frame-numbering.patch` — keeps requests and parameters
  numbered after the last frame whose statistics the IPA processed, as
  rkisp1 does. The ISP runs on every frame, requests or not, so when the
  application stalled for ~0.5 s (as `rtspclientsink` does setting up its
  session), the statistics overwrote frame contexts that requests were
  still numbered for and the IPA aborted (`Frame context for 6 has been
  overwritten by 22`).

libcamera's `src` is pinned in `default.nix` to the rkisp2 v3 branch rather
than carrying the other 45 commits as files.

## Checking it on the board

The ISP runs memory-to-memory: VICAP captures raw frames, userspace hands
them back to the ISP through `rkisp2_rawrd0`. So there are two media devices
and no device tree link between them.

```sh
# Sensor probed on i2c2?
dmesg | grep -iE 'ov13855|rkisp2|rkcif|csi2'

# Two media devices: "rockchip-cif" and "rkisp2"
media-ctl -p -d /dev/media0
media-ctl -p -d /dev/media1

# libcamera should list exactly one camera
cam -l

# Grab a few frames without mediamtx in the way
cam -c1 --capture=10
```

The pipeline handler follows the links from the sensor, so if `cam -l` finds
nothing, check the chain the sensor is on: sensor → `dw-mipi-csi2rx
fdd20000.csi` → `rkcif-mipi1` → `rkcif-mipi1-id0`. On the ISP side it looks for
`rkisp2_isp`, `rkisp2_rawrd0` and `rkisp2_mainpath`.

The stream is at `rtsp://zucchini:8554/cam`, encoded on demand and shut down
10s after the last viewer disconnects.

## Known rough edges

- **The stream is MJPEG, not H.264.** The H.264/HEVC block (rkvenc2) has no
  mainline driver, so the stream uses the `vepu121` hardware JPEG encoder
  instead: ~10% of a core, where x264 needed ~2.5 cores, but ~20 Mbit/s at
  quality 75 where H.264 needed 4.
- **The tuning file is a starting point, not a calibration.** No colour
  correction matrix and no lens shading correction — expect undersaturated
  colour and corner vignetting. `utils/tuning/rkisp2.py` in the libcamera
  tree generates real ones from captures.
- **No autofocus.** The rkisp2 IPA has no AF algorithm. The VCM is exposed as
  a subdev; set focus by hand with `V4L2_CID_FOCUS_ABSOLUTE`.
- **Stopping a stream takes a second.** rkisp2 stops its output DMA at a
  frame end, as rkisp1 does, but here the ISP is fed from memory and no more
  frames come once userspace stops, so it falls back to a forced stop after
  a 1 s timeout (counted in debugfs `mp_stop_timeout`).
