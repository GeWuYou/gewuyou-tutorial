# Gitea 的安装与基础配置（Docker Compose 方式）

> 本节将指导你完成 **使用 Docker Compose 安装 Gitea** 的全过程，包括准备环境、配置 Compose 文件、启动服务及简单配置。

## 🎯 教程目标

- 本节你将学到：
  - 如何使用 Docker 和 Docker Compose 安装 Gitea；
  - 如何配置 Gitea 的服务参数和数据存储；
  - 如何通过浏览器访问并初始化 Gitea 实例。

## 📦 步骤说明

### 1. 环境准备

确保你的系统中已经安装了以下组件：

- Docker
- Docker Compose

如未安装，可参考前面的章节：[一键安装 Docker + Compose](../../docker/one-click-install/README.md)

### 2. 创建项目目录结构

```bash
mkdir -p ~/docker/gitea
cd ~/docker/gitea
```

### 3. 编写 `docker-compose.yml` 文件

在 `~/docker/gitea` 目录下创建 `docker-compose.yml`：

```yaml
version: "3.8" # 如果你使用的是最新版本的docker compose 请删除此行

services:
  gitea:
    image: gitea/gitea:latest  # 使用官方 Gitea 最新版本镜像
    container_name: gitea      # 容器的名字，方便识别

    environment:               # 设置环境变量，配置 Gitea 启动参数
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=postgres     # 使用 PostgreSQL 作为数据库
      - GITEA__database__HOST=gitea-db:5432   # 数据库主机地址和端口（指向下面的服务）
      - GITEA__database__NAME=gitea           # 数据库名称
      - GITEA__database__USER=gitea           # 数据库用户名
      - GITEA__database__PASSWD=s1tGsUUMAWLq      # 建议强密码

    restart: unless-stopped    # 容器在非正常退出时自动重启，除非手动停止

    volumes:                  # 将主机目录挂载到容器内部，实现数据持久化
      - ./gitea:/data/gitea         # Gitea 核心数据（仓库、用户文件等）
      - /etc/timezone:/etc/timezone:ro    # 共享主机时区配置，只读挂载
      - /etc/localtime:/etc/localtime:ro  # 共享主机时间设置，只读挂载

    ports:                    # 端口映射，主机 → 容器
      - "3001:3000"           # 网页 UI：主机 3001 映射容器 3000
      - "2222:22"             # SSH 访问：主机 2222 映射容器 22

    depends_on:              # 定义依赖关系，确保数据库先启动并健康后再启动 Gitea
      gitea-db:
        condition: service_healthy
  gitea-db:
    image: postgres:latest    # 使用最新 PostgreSQL 镜像
    container_name: gitea_db  # 容器名称
    environment:              # 设置 PostgreSQL 的初始化参数
      - POSTGRES_USER=gitea          # 初始化数据库用户
      - POSTGRES_PASSWORD=s1tGsUUMAWLq  # 建议强密码
    volumes:
      - ./gitea-db:/var/lib/postgresql/data  # 本地目录挂载到容器内数据目录
    healthcheck:              # 健康检查配置，确保数据库已准备好
      test: ["CMD-SHELL", "pg_isready -U gitea"]  # 测试数据库是否可连接
      interval: 5s            # 每 5 秒执行一次检查
      timeout: 5s             # 检查超时时间 5 秒
      retries: 5              # 连续 5 次失败视为不健康
    restart: unless-stopped    # 容器在非正常退出时自动重启，除非手动停止
```

### 4. 启动服务

```bash
docker-compose up -d
```

首次启动可能需要等待数秒钟到 1 分钟，取决于网络和系统资源。

### 5. 访问 Gitea 界面并初始化

打开浏览器，访问：[http://localhost:3001](http://localhost:3001)

进行如下初始化配置：

- 数据库类型：PostgreSQL
- 主机名：`db:5432`
- 用户名：`gitea`
- 密码：`s1tGsUUMAWLq`(这里替换成你自己的密码)
- 数据库名称：`gitea`

其他设置保持默认，点击“安装 Gitea”。

> 初始化完成后将自动跳转至登录页面。

## 🎥 视频地址

👉 敬请期待（录制完成后补充）

## ❓ 常见问题

### Q: 为什么我访问 [http://localhost:3001](http://localhost:3001) 页面打不开？

- 请确认 Docker 服务正在运行；
- 使用 `docker ps` 查看容器是否已启动；
- 检查端口是否被占用。

### Q: 数据会丢失吗？

- 本教程的 Docker Compose 配置已挂载本地目录到容器，可持久化数据；
- 请定期备份 `~/docker/gitea` 目录下的数据。

---

> 本节内容遵循 Apache 2.0 协议，欢迎引用与转载，需保留原始署名。
