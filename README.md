# smokefire 1.0.0 部署交付

深圳市嘟嘟喵科技有限公司提供的烟火 / 抽烟视频 AI 辅助告警系统部署仓库。

本仓库面向部署与使用，不包含项目源码树。可运行交付物、两个模型权重以及离线 Docker 镜像位于 GitHub Release `v1.0.0`：

- `smokefire-deploy-1.0.0-cpu.zip`：完整 CPU 独立部署包；
- `fire_smoke_v5.pt`：火焰 / 烟雾模型；
- `smoking_v4.pt`：抽烟模型。

## 快速开始

1. 在 Releases 下载并解压 `smokefire-deploy-1.0.0-cpu.zip`。
2. Windows 运行 `start.ps1`；Linux 运行 `start.sh`。
3. 在服务主机打开 `http://127.0.0.1:8600`。

完整安装、校验、备份、升级与验收要求请先阅读：

- [中文部署手册](docs/smokefire-部署手册.pdf)
- [中文使用操作手册](docs/smokefire-使用操作手册.pdf)
- [中文模型能力实测手册](docs/smokefire-模型能力实测手册.pdf)
- [Deployment Guide](docs/smokefire-Deployment-Guide.pdf)
- [User Operation Manual](docs/smokefire-User-Operation-Manual.pdf)
- [Model Capability Test Guide](docs/smokefire-Model-Capability-Test-Guide.pdf)

模型能力、阈值和样本结果的适用边界以《模型能力实测手册》为准。系统是 AI 辅助告警工具，不能替代法定消防设施、人工巡检、应急流程和现场复核。

---

## English

This repository is the deployment and user-delivery surface for smokefire 1.0.0 by Shenzhen Dudumiao Technology Co., Ltd. It does not contain the project source tree.

Download `smokefire-deploy-1.0.0-cpu.zip` from Release `v1.0.0`, run `start.ps1` on Windows or `start.sh` on Linux, then open `http://127.0.0.1:8600` on the service host. Use the English PDF links above for installation, operation, and tested capability boundaries.

