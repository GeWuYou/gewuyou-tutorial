# 安装 Runner 与 CI/CD 集成（Gitea Actions）

> 本节将指导你完成 **安装 Gitea Actions Runner 并实现 CI/CD 集成** 的全过程，使用 Gitea 自带的 Actions 功能完成自动化构建与部署。

## 🎯 教程目标

- 本节你将学到：
  - 如何部署 Gitea Actions Runner；
  - 如何注册 Runner 到 Gitea；
  - 如何编写 `.gitea/workflows` 工作流文件；
  - 如何触发 CI/CD 流程。

## 📦 步骤说明

### 1. 环境准备

- 已成功安装并运行 Gitea（1.20+ 推荐使用 1.21 或更高）；
- Gitea 服务已开启 Actions 支持（默认开启）；
- 创建了一个普通项目用于测试 CI/CD。

### 2. 操作步骤

#### 2.1 下载并运行 Runner

> [官方 Runner 地址](https://gitea.com/gitea/act_runner)

```bash
mkdir -p ~/gitea-runner && cd ~/gitea-runner

curl -L https://gitea.com/gitea/act_runner/releases/latest/download/act_runner-linux-amd64 -o act_runner
chmod +x act_runner
```

#### 2.2 注册 Runner 到 Gitea

执行以下命令注册 Runner：

```bash
./act_runner register
```

根据提示填写信息：

- **Gitea 实例地址**：`http://<你的Gitea地址>:3000`
- **Runner 名称**：如 `my-runner`
- **Token**：进入 Gitea → 管理后台 → Actions Runners → 添加 Runner → 获取注册用 Token
- **平台类型**：`linux/amd64`
- **执行器类型**：建议选择 `docker`

注册完成后会生成 `config.yaml`，包含 Runner 的注册信息。

#### 2.3 启动 Runner

```bash
./act_runner daemon
```

也可以放到后台执行或使用 systemd 管理。

#### 2.4 编写 CI/CD Workflow

在你的 Gitea 项目中创建 `.gitea/workflows/ci.yml` 文件：

```yaml
name: build-and-test

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Build
        run: npm run build

      - name: Test
        run: npm test
```

> ✅ Push 到仓库后，Gitea 会自动触发 Workflow 执行。

### 3. 查看执行状态

1. 进入 Gitea 仓库页面；
2. 点击 “Actions” 标签；
3. 查看每次提交触发的构建详情与日志。

## 🎥 视频地址

👉 敬请期待（录制完成后补充）

## ❓ 常见问题

### Q: Gitea 中找不到 Actions 标签页？

请确保：
- Gitea 版本为 1.20 及以上；
- 配置文件 `app.ini` 中 `[actions] ENABLED = true`；
- 启用了后台任务处理器（默认开启）。

### Q: Runner 启动后无响应？

- 确保 Gitea 能访问 Runner；
- 查看 Runner 日志是否注册成功；
- 确保 Gitea 服务可从 Runner 所在机访问（特别是 Docker 网络）。

### Q: 可以运行多个 Runner 吗？

可以。你可以部署多个 Runner 分布在不同机器或同一台机器，注册多个后 Gitea 会自动调度。

---

> 本节内容遵循 Apache 2.0 协议，欢迎引用与转载，需保留原始署名。
