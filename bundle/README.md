# smokefire 1.0.0 独立部署包

编制单位：深圳市嘟嘟喵科技有限公司  
项目地址：https://github.com/newtv-ai/smokefire

本交付包含预构建的 smokefire 与 go2rtc Docker 镜像、两个模型权重、启停/配置脚本和中英文 PDF 手册，不包含项目源码。CPU 包的离线镜像已放在 `images/`；GPU 包需把同一 Release 中全部 `smokefire-images.tar.gz.partNN` 放入 `images/` 后再启动。目标机只需要 Docker Engine / Docker Desktop 与 Docker Compose v2，不需要 Python、Git 或编译环境；GPU 主机还需 NVIDIA 驱动和 NVIDIA Container Toolkit。

## 启动

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

Linux：

```bash
chmod +x verify.sh start.sh stop.sh configure-go2rtc.sh
./start.sh
```

启动脚本第一步会自动校验交付文件，不需要另外运行 `verify`。校验失败会直接停下并指出是哪个文件。

启动成功后，在服务主机打开 `http://127.0.0.1:8600`。

## 视频流接入

- 直接 RTSP：保持默认配置，在界面添加摄像头或 NVR 地址。
- 内置 go2rtc：执行 `configure-go2rtc` 脚本并选择 `builtin`，系统自动让检测与录像共享同一上游连接。
- 用户现有 go2rtc：选择 `upstream`，只填一次 API 与 RTSP 基址。smokefire 读取 `/api/streams`，自动导入全部主码流，不需要逐个添加摄像头，也不会修改用户的 go2rtc 配置。

同一台宿主机上的现有 go2rtc，从容器内通常使用 `host.docker.internal`：

```powershell
.\configure-go2rtc.ps1 -Mode upstream -Api http://host.docker.internal:1984 -Rtsp rtsp://host.docker.internal:8554
```

```bash
./configure-go2rtc.sh upstream http://host.docker.internal:1984 rtsp://host.docker.internal:8554
```

详细步骤、备份、升级与验收要求见 `docs/` 中的部署手册。

---

# smokefire 1.0.0 Standalone Deployment Bundle

Prepared by Shenzhen Dudumiao Technology Co., Ltd.  
Project: https://github.com/newtv-ai/smokefire

This source-free delivery contains prebuilt smokefire and go2rtc Docker images, both model weights, lifecycle/configuration scripts, and Chinese/English PDF manuals. The CPU bundle already has its archive under `images/`. For the GPU bundle, place every `smokefire-images.tar.gz.partNN` asset from the same Release under `images/` before startup. The host needs Docker Engine/Desktop and Docker Compose v2; a GPU host also needs the NVIDIA driver and NVIDIA Container Toolkit.

For an existing go2rtc installation, configure its API and RTSP base URLs once. smokefire reads `/api/streams` and imports every main stream automatically without changing the customer's go2rtc configuration. See the deployment guide under `docs/` for all three integration modes and acceptance checks.
