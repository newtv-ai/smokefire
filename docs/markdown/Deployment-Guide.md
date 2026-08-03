# smokefire Fire, Smoke & Smoking Detection

## Deployment Guide

**Prepared by: Shenzhen Dudumiao Technology Co., Ltd.**  
**Document version: V1.0**  
**Applicable software version: 1.0.0**  
**Updated: 2026-08-03**

> smokefire is an AI-assisted video alerting tool, not a certified fire alarm device. It does not replace statutory fire protection, human patrols, emergency procedures, or on-site verification. False alerts and missed events are possible.

---

## Document information

| Item | Value |
|---|---|
| Document | smokefire Deployment Guide |
| Audience | Implementation engineers, administrators, and site operators |
| Standard delivery | Standalone Docker CPU bundle without the project source tree |
| Host platforms | Windows 10/11, Windows Server, mainstream x86_64 Linux |
| Default URL | `http://127.0.0.1:8600` |
| Project | `https://github.com/newtv-ai/smokefire` |

## Contents

1. Delivery method and requirements
2. Download and verification
3. Windows deployment
4. Linux deployment
5. First start and acceptance
6. Camera preparation
7. Configuration and LAN access
8. Routine operation
9. Backup, restore, and upgrade
10. Troubleshooting
11. Handover checklist

---

## 1. Delivery method and requirements

### 1.1 Standard bundle

Download `smokefire-deploy-1.0.0-cpu.zip` from GitHub Release `v1.0.0`. The bundle contains:

- a prebuilt smokefire CPU Docker image;
- `fire_smoke_v5.pt` and `smoking_v4.pt` model weights;
- Docker Compose configuration;
- Windows and Linux start/stop scripts;
- Chinese and English deployment, operation, and model-test PDFs;
- a SHA-256 manifest.

The bundle does not contain the project source tree. The target host does not need Python, Git, or build tools, and the service does not require GitHub after installation.

### 1.2 Host requirements

| Item | Recommended minimum | Notes |
|---|---|---|
| CPU | x86_64, 4 cores | Benchmark the planned stream count; the CPU package targets pilots and smaller installations |
| Memory | 8 GB | 16 GB or more is recommended |
| Disk | 20 GB free | Add capacity for event video, snapshots, and backups |
| Docker | Docker Engine/Desktop 24+ | Docker Compose v2 is required |
| Browser | Maintained Chrome or Edge | Used for the web interface |
| Camera | RTSP, H.264 recommended | The host must reach each camera or NVR |

The standard package is CPU-only. Multi-stream production use requires validation with actual streams on the target host. Obtain a separate GPU bundle matched to the NVIDIA driver and CUDA environment when GPU acceleration is required.

---

## 2. Download and verification

Open `https://github.com/newtv-ai/smokefire`, go to Releases, select `v1.0.0`, and download:

```text
smokefire-deploy-1.0.0-cpu.zip
```

On Windows, extract to a path without non-ASCII characters or spaces, for example `D:\smokefire`.

Linux example:

```bash
sudo mkdir -p /opt/smokefire
sudo unzip smokefire-deploy-1.0.0-cpu.zip -d /opt/smokefire
cd /opt/smokefire
```

Verify on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

Verify on Linux:

```bash
chmod +x verify.sh start.sh stop.sh
./verify.sh
```

Model reference hashes:

| File | Size | SHA-256 |
|---|---:|---|
| `models/fire_smoke_v5.pt` | 44,014,233 bytes | `b5248d55c5d90e341bc4e537887d4bce4b9af1bd0330ddd87825294750a1e216` |
| `models/smoking_v4.pt` | 44,025,689 bytes | `0ea7b66c2105f1898f56f828b18ffb01934fb1f47a795192e8867ae8fcb128dd` |

Do not continue when verification fails. Download the affected file again.

---

## 3. Windows deployment

Install Docker Desktop, select Linux containers, and wait for the engine to start. In PowerShell, verify:

```powershell
docker version
docker compose version
```

From the extracted bundle directory, start smokefire:

```powershell
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

The script verifies the package, imports the prebuilt image, starts the container, and waits for the health check. The first image import can take several minutes.

Status and logs:

```powershell
docker compose ps
docker compose logs -f smokefire
```

`Ctrl+C` exits log viewing without stopping the service.

Stop and restart:

```powershell
powershell -ExecutionPolicy Bypass -File .\stop.ps1
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

The stop script preserves the event-data volume.

---

## 4. Linux deployment

Install Docker Engine and Compose v2 using the distribution's official instructions, then verify:

```bash
docker version
docker compose version
```

Add `sudo` if the current account does not have Docker access, or have an administrator configure the Docker group and log in again.

Start:

```bash
cd /opt/smokefire
chmod +x verify.sh start.sh stop.sh
./start.sh
```

Status and logs:

```bash
docker compose ps
docker compose logs -f smokefire
```

Stop and restart:

```bash
./stop.sh
./start.sh
```

`restart: unless-stopped` brings the container back when Docker restarts. Validate one complete host reboot before production handover.

---

## 5. First start and acceptance

Open `http://127.0.0.1:8600` on the service host. Loading both models for the first time may take from tens of seconds to several minutes.

Health endpoints:

| Endpoint | Purpose | Expected result |
|---|---|---|
| `/api/health/live` | Process liveness | HTTP 200 |
| `/api/health/ready` | Models, scheduling, recording, and disk readiness | HTTP 200 |
| `/api/status` | Runtime and notification metrics | JSON response |

```bash
curl http://127.0.0.1:8600/api/health/live
curl http://127.0.0.1:8600/api/health/ready
```

Minimum acceptance:

1. Open Live Wall, Event Center, and Camera Management.
2. Add one authorized RTSP camera.
3. Confirm the camera becomes Online and the image/name are correct.
4. Trigger one alert with authorized test material or a controlled site test.
5. Confirm the snapshot, class, confidence, time, and video in Event Center.
6. Test both Confirmed and False Positive actions.
7. Restart the service and confirm camera configuration and history remain.

Successful installation is not final production acceptance. Validate capacity, latency, false alerts, misses, evidence completeness, stream recovery, and continuous operation with the real network, storage, and planned camera count.

---

## 6. Camera preparation

Prepare the camera name, RTSP URL, credentials, NVR subnet, codec, resolution, bitrate, and planned stream count.

Windows connectivity check:

```powershell
Test-NetConnection <camera-ip> -Port 554
```

Linux:

```bash
nc -vz <camera-ip> 554
```

Example RTSP URL:

```text
rtsp://user:password@192.168.1.20:554/stream1
```

Prefer H.264 main streams or a substream sized for available compute. Validate H.265, very high resolutions/bitrates, and vendor-specific packaging separately.

---

## 7. Configuration and LAN access

The bundle binds the web port to `127.0.0.1:8600` by default. For access from other LAN computers, the implementer must bind the port to the intended private IP in `docker-compose.yml`, set the allowed host names in `.env`, and restart the service.

Common `.env` settings:

| Setting | Default | Purpose |
|---|---|---|
| `SMOKEFIRE_ALLOWED_HOSTS` | `localhost,127.0.0.1` | Allowed HTTP Host values |
| `SMOKEFIRE_WEBHOOK_URL` | empty | Global webhook endpoint |
| `SMOKEFIRE_INFER_WORKERS` | `4` | CPU inference workers |
| `SMOKEFIRE_INFER_BATCH_MAX` | `8` | Maximum inference batch |
| `SMOKEFIRE_STOP_GRACE_PERIOD` | `180s` | Graceful shutdown allowance |

Restart after global environment changes. Per-camera detection settings apply after saving in Camera Management.

Camera credentials may appear inside RTSP URLs. Restrict access to the deployment directory, backups, and terminal history, and never expose full credentials in screenshots or tickets.

---

## 8. Routine operation

Recommended daily checks:

```bash
docker compose ps
docker compose logs --tail 200 smokefire
curl http://127.0.0.1:8600/api/health/ready
```

Also confirm that cameras are online, previews update, recent events play, and disk usage is below the high-water threshold. Do not run `docker compose down -v`; it deletes the named business-data volume.

---

## 9. Backup, restore, and upgrade

Business data resides in the `smokefire-data` named volume. Stop the service before backup when practical, record the current version, and use an administrator-approved Docker-volume method to copy the complete `/app/data` tree.

A complete backup includes camera configuration, the SQLite database, event clips, snapshots, false-positive feedback, and the notification queue. A database-only copy is not a complete evidence backup.

Restore:

1. Stop the service.
2. Restore the complete data tree for the same software version.
3. Start the service.
4. Verify health, cameras, history, clips, and feedback.

Upgrade:

1. Back up the data volume and confirm the backup is readable.
2. Download and verify the new bundle.
3. Stop the old version and run the new bundle's start script.
4. Repeat health and minimum business acceptance.
5. If required, stop the new version and restore the old image plus the pre-upgrade backup.

---

## 10. Troubleshooting

| Symptom | Check first | Action |
|---|---|---|
| Docker command unavailable | Docker Desktop/Engine state | Start the engine and retry `docker version` |
| Image archive missing | Completeness of `images/` and the ZIP | Download again and run verification |
| Readiness does not pass | Container logs, model hashes, free disk | `docker compose logs --tail 300 smokefire` |
| Web page unavailable | Container state, port 8600, bind address | Test `127.0.0.1` on the host first |
| Camera keeps reconnecting | RTSP URL, credentials, port 554, codec | Test the same RTSP URL in a player on the host |
| Preview black while Online | Browser decode, jitter, first closed segment | Refresh and inspect stream/FFmpeg logs |
| No alerts | Capability switch, thresholds, target size | Use an authorized positive sample; do not sharply lower thresholds without replay testing |
| Too many alerts | Steam, fog, reflections, eating, handheld objects | Collect false positives and tune against the same positive/negative set |
| Event has no clip | Disk, recording warm-up, source stability | Check storage and FFmpeg logs |
| Disk nearly full | Retention and backup policy | Back up first, then delete by date in Storage Management |

---

## 11. Handover checklist

### Installation

- [ ] Bundle, image, and both model hashes verified.
- [ ] Start, stop, restart, and host-reboot recovery tested.
- [ ] `/api/health/live` and `/api/health/ready` healthy.
- [ ] All three business pages open.
- [ ] Installation directory, data volume, backup location, and version recorded.
- [ ] Backup and restore method tested.

### Business acceptance

- [ ] Planned cameras connected with correct names, time, and images.
- [ ] Alert snapshots and event clips play correctly.
- [ ] Confirmed, false-positive archive, and feedback export tested.
- [ ] Webhook delivery tested when enabled.
- [ ] Target-scene positives and negatives used to validate misses, false alerts, and alert latency.
- [ ] Capacity, reconnect behavior, and continuous operation tested at the planned stream count.
- [ ] Users received the Operation Manual and Model Capability Test Guide and completed handover training.

---

**Prepared by: Shenzhen Dudumiao Technology Co., Ltd.**  
**Project: https://github.com/newtv-ai/smokefire**

