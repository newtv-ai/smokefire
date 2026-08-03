# smokefire 1.0.0 部署交付

深圳市嘟嘟喵科技有限公司提供的烟火 / 抽烟视频 AI 辅助告警系统部署仓库。

本仓库面向最终用户部署与使用，仓库保持 **PRIVATE**，不包含项目源码树。Release `v1.0.0` 提供已经构建好的 CPU、NVIDIA GPU 离线运行包、两套模型权重、启动与校验脚本，以及中英文手册。

## 发布文件

- `smokefire-deploy-1.0.0-cpu.zip`：完整 CPU 离线部署包，已包含 smokefire、go2rtc 镜像和两套权重；
- `smokefire-deploy-1.0.0-gpu.zip`：NVIDIA GPU 部署包，已包含两套权重、脚本、配置和手册；
- `smokefire-images.tar.gz.partNN`：GPU 离线镜像的全部分卷，使用 GPU 包时必须全部下载；
- `fire_smoke_v5.pt`、`smoking_v4.pt`：单独提供的模型权重备份；
- `SHA256SUMS-v1.0.0.txt`：全部 Release 文件的 SHA-256。

## 快速开始

CPU：下载并解压 `smokefire-deploy-1.0.0-cpu.zip`，Windows 运行 `start.ps1`，Linux 运行 `start.sh`。

GPU：下载并解压 `smokefire-deploy-1.0.0-gpu.zip`，再把 Release 中全部 `smokefire-images.tar.gz.partNN` 放入解压目录的 `images/`，然后运行启动脚本。GPU 主机需预先安装 NVIDIA 驱动、Docker 和 NVIDIA Container Toolkit。

服务启动后，在服务主机打开 `http://127.0.0.1:8600`。

## 视频流接入

交付包支持三种模式：

1. 直接填写摄像机 / NVR 的 RTSP 地址；
2. 使用交付包自带 go2rtc 做复用；
3. 对接用户已有 go2rtc：只配置一次 API 基址和 RTSP 基址，smokefire 会读取 `GET /api/streams`，批量同步全部主码流，不需要逐路手工添加。

同一主机上的既有 go2rtc，从容器内通常使用：

```text
API  http://host.docker.internal:1984
RTSP rtsp://host.docker.internal:8554
```

完整命令、子码流过滤、流删除与恢复规则见部署手册。

## 文档

- [中文部署手册](docs/smokefire-部署手册.pdf)
- [中文使用操作手册](docs/smokefire-使用操作手册.pdf)
- [中文模型能力实测手册](docs/smokefire-模型能力实测手册.pdf)
- [Deployment Guide](docs/smokefire-Deployment-Guide.pdf)
- [User Operation Manual](docs/smokefire-User-Operation-Manual.pdf)
- [Model Capability Test Guide](docs/smokefire-Model-Capability-Test-Guide.pdf)

模型实测手册统一使用默认置信度阈值 `0.30`，检测框由 `fire_smoke_v5.pt` / `smoking_v4.pt` 实际推理生成，没有人工补框。系统是 AI 辅助告警工具，不能替代法定消防设施、人工巡检、应急流程和现场复核。

英文说明见 [README.en.md](README.en.md)。
