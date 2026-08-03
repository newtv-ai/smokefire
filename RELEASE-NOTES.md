# v1.0.0 Release Notes

Release date: 2026-08-03  
Prepared by: Shenzhen Dudumiao Technology Co., Ltd. / 深圳市嘟嘟喵科技有限公司

## Delivery scope

- Source-tree-free CPU offline bundle with the prebuilt smokefire and go2rtc images, both weights, scripts, configuration, and six PDF manuals.
- Source-tree-free NVIDIA GPU bundle plus all required split offline image parts.
- Existing-go2rtc integration through one API/RTSP endpoint pair; all main streams are synchronized from `GET /api/streams` without per-camera entry.
- Chinese and English deployment, operation, and model capability manuals, all labeled software version 1.0.0.
- Public-dataset model brochure with 30 actual inference samples at the default confidence threshold 0.30.

## Validation performed

- CPU offline image export includes both `smokefire:1.0.0-cpu` and `alexxit/go2rtc:1.9.9`.
- NVIDIA GPU image reports PyTorch 2.9.1+cu128, CUDA available, and loads and warms both delivered weights on an RTX 4080 Laptop GPU.
- GPU service reaches HTTP 200 readiness after both model capabilities complete warm-up.
- Existing-go2rtc end-to-end test imports main streams, filters a `_sub` stream, disables a missing upstream stream, and restores it automatically when it reappears.
- All six PDFs pass text checks, A4 rendering, and visual page inspection.

Use `SHA256SUMS-v1.0.0.txt` to verify all downloaded Release assets before deployment.
