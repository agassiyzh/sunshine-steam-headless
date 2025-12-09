# sunshine-steam-headless

## 概述

这是一个面向 **NVIDIA (575 驱动) + 3070Ti** 的 headless Sunshine 镜像工程：使用 Xorg + nvidia 驱动的 dummy/虚拟显示，让 Sunshine 能在没有物理显示器的容器中使用 NVENC。

## 先决条件（宿主机）

1. 已安装 NVIDIA 驱动（例如 575.x），能正常运行 `nvidia-smi`。
2. 已安装并配置 nvidia-container-toolkit（让容器能访问 GPU）。
3. Docker / Docker Compose 已安装。

## 构建与运行

```bash
# 构建并启动
./run-build.sh

# 查看日志
docker logs -f sunshine-headless