# 一键安装 Docker

> 本节将指导你完成 **一键安装 Docker** 的全流程操作。  
> 提供适用于 **Debian / Ubuntu / CentOS / Rocky** 等主流 Linux 系统的统一安装脚本。  
> 自动完成：卸载旧版本、安装最新 Docker Engine、安装 Compose 插件、配置国内镜像源、设置开机启动。

---

## 🎯 教程目标

- 本节你将学到：
  - 使用官方推荐的安装脚本快速安装 Docker
  - 自动配置镜像源
  - 启用开机自启并验证安装

---

## 📦 步骤说明

### 1. 环境准备

| 项目     | 要求                                                         |
| -------- | ------------------------------------------------------------ |
| 操作系统 | Debian / Ubuntu / CentOS / Rocky / AlmaLinux（推荐 x86_64 / aarch64） |
| 权限     | 具备 `sudo` 权限或 root                                      |
| 网络     | 可访问 Docker 官方资源 或 通过代理访问（脚本可手动修改）     |
| 工具依赖 | curl / bash / systemd                                        |

---

### 2. 操作步骤

#### 2.1 使用脚本自动安装

你可以使用以下脚本进行快速安装：

```bash
curl -fsSL https://get.docker.com | sudo sh
```

或者使用其它镜像加速版本：

```bash
curl -fsSL https://get.docker.com | sudo sh -s -- --mirror Aliyun
curl -fsSL https://get.docker.com | sudo sh -s -- --mirror AzureChinaCloud
```

#### 2.2 启动Docker

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

> ✅ 安装成功后可使用 `docker -v`和`docker compose version` 进行验证。

---

#### 2.3 添加国内镜像加速器（可选）

```bash
sudo mkdir -p /etc/docker

cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "registry-mirrors": [
        "https://docker.mirrors.sjtug.sjtu.edu.cn",
        "https://cr.laoyou.ip-ddns.com",
        "https://docker.1panel.live",
        "https://image.cloudlayer.icu",
        "https://hub.fast360.xyz",
        "https://docker-0.unsee.tech",
        "https://docker.1panelproxy.com",
        "https://docker.tbedu.top",
        "https://dockerpull.cn",
        "https://docker.m.daocloud.io",
        "https://hub.rat.dev",
        "https://docker.kejilion.pro",
        "https://docker.hlmirror.com",
        "https://docker.imgdb.de",
        "https://docker.melikeme.cn",
        "https://ccr.ccs.tencentyun.com"
      ]
}
EOF
sudo systemctl daemon-reexec
sudo systemctl restart docker
```

---

#### 2.5 非 root 用户配置（可选）

```bash
sudo usermod -aG docker $USER
# 注：执行完需重新登录终端
```

---

## 🎥 视频地址

[一键安装 Docker](https://www.bilibili.com/video/BV1QyTyz1E1K/)

---

## ❓ 常见问题

| 问题                                     | 解决方法                                                     |
| ---------------------------------------- | ------------------------------------------------------------ |
| `curl: command not found`                | 使用 `sudo apt install curl` 或 `sudo yum install curl` 安装 |
| `Cannot connect to the Docker daemon`    | Docker 服务未启动：请执行 `sudo systemctl start docker`      |
| `permission denied /var/run/docker.sock` | 用户未加入 docker 组，见上方 2.5 配置方法                    |
| `docker: command not found`              | 脚本未执行成功，或未加载 PATH，尝试重新登录或手动检查安装目录 |
| `docker compose version` 无输出          | 可能未正确安装 compose-plugin，尝试重新执行安装命令          |

---

> 本节内容遵循 **Apache 2.0 协议**，欢迎引用与转载，需保留原始署名。
