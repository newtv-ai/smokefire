# v1.0.0 Release Notes

Release date: 2026-08-03  
Prepared by: Shenzhen Dudumiao Technology Co., Ltd. / 深圳市嘟嘟喵科技有限公司

## Assets

- `smokefire-deploy-1.0.0-cpu.zip` — complete source-tree-free CPU deployment bundle.
- `fire_smoke_v5.pt` — fire and smoke detection weight.
- `smoking_v4.pt` — smoking detection weight.
- `SHA256SUMS-v1.0.0.txt` — hashes for the three assets above.

The complete bundle contains the prebuilt Docker runtime image, both weights, lifecycle scripts, Compose configuration, and six Chinese/English PDF manuals. It was validated by extracting the final ZIP into an isolated directory, importing the image, starting the service, checking both weight hashes inside the container, receiving HTTP 200 from liveness/readiness endpoints, opening all three business pages, and stopping while preserving the data volume.

The standard package is CPU-only. Multi-stream production capacity must be validated on the target host with the actual camera streams.

