# GitLab安装Runner

> 本节将指导你完成 **安装 GitLab Runner** 的全过程

## 🎯 教程目标

- 本节你将学到：
  - 如何部署 GitLab Runner（基于 Docker）；
  - 如何注册 Runner 到 GitLab；
  - 如何编写简单的示例 `.gitlab-ci.yml` 工作流文件；
  - 如何理解不同类型的 Runner；

## 📦 步骤说明

### 1. 环境准备

- 已成功安装并运行 GitLab（建议版本 14.0 及以上）；
- GitLab 服务已开启 CI/CD 功能（默认开启）；
- 已创建一个普通项目用于测试 CI/CD。

### 2. 操作步骤

#### 2.1 使用 Docker 启动 Runner 容器

> 推荐将 Runner 与 GitLab 分开部署，方便维护。最好使用docker-compose.yml维护

1. 创建一个目录用于保存 Runner 数据，例如：

```bash
mkdir -p ~/docker/gitlab/runners
cd ~/docker/gitlab/runners
```

2. 启动 Runner 容器：

```bash
docker run -d \
  --name gitlab-runner \
  --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest
```

---

#### 2.2 注册 Runner 到 GitLab

Runner 启动后，需要注册到 GitLab 实例才能使用。

1. 获取注册令牌：
   - 进入 GitLab 项目页面
   - 点击左侧 Settings -> CI/CD
   - 展开 Runners 部分
   - 找到 Registration token 或使用 Specific runner 提供的令牌

2. 运行注册命令：

```bash
docker exec -it gitlab-runner gitlab-runner register
```

按照提示输入以下信息：
- GitLab 实例 URL（例如：http://gitlab.example.com）
- 注册令牌（Registration token）
- Runner 描述（例如：my-runner）
- 标签（可选，例如：docker,linux）
- 是否锁定到当前项目（true/false）
- 选择执行器类型（通常选择 docker）

3. 配置 Runner 使用 Docker 执行器：

注册完成后，需要配置 Runner 使用 Docker 执行器来运行作业。

编辑配置文件：

```bash
docker exec -it gitlab-runner nano /etc/gitlab-runner/config.toml
```

确保配置包含类似内容：

```toml
[[runners]]
  name = "my-runner"
  url = "http://gitlab.example.com/"
  token = "your-token"
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
```

---

#### 2.3 编写示例 CI/CD Pipeline

创建 `.gitlab-ci.yml`：

```yaml
stages:
  - build
  - test
  - deploy

variables:
  MAVEN_OPTS: "-Dhttps.protocols=TLSv1.2 -Dmaven.repo.local=.m2/repository"
  MAVEN_CLI_OPTS: "--batch-mode --errors --fail-at-end --show-version"

before_script:
  - echo "Beginning of the pipeline"

build-job:
  stage: build
  script:
    - echo "Compiling the code..."
    - echo "Compile complete."

unit-test-job:
  stage: test
  script:
    - echo "Running unit tests..."
    - echo "Unit tests passed."

lint-test-job:
  stage: test
  script:
    - echo "Linting code..."
    - echo "Code linting passed."

deploy-job:
  stage: deploy
  script:
    - echo "Deploying application..."
    - echo "Application successfully deployed."
  only:
    - main
```

推送代码到 GitLab

---

#### 2.4 Runner 类型说明与应用场景

GitLab 支持多种类型的 Runner：

| 类型         | 注册方式               | 适用范围                 | 应用场景                     |
| ------------ | ---------------------- | ------------------------ | ---------------------------- |
| Shared       | Admin area             | 所有项目                 | 公共资源，所有项目共享       |
| Group        | Group CI/CD settings   | 组内所有项目             | 团队内部共享                 |
| Specific     | Project CI/CD settings | 当前单个项目             | 项目专用，安全隔离           |

##### 示例：配置不同类型的 Runner

在 `/etc/gitlab-runner/config.toml` 中可以配置多个 Runner：

```toml
concurrent = 4
check_interval = 0

[[runners]]
  name = "shared-runner"
  url = "http://gitlab.example.com/"
  token = "shared-token"
  executor = "docker"
  [runners.docker]
    image = "ubuntu:20.04"

[[runners]]
  name = "specific-project-runner"
  url = "http://gitlab.example.com/"
  token = "specific-token"
  executor = "shell"
```

---

### 3. 查看执行状态

1. 打开 GitLab 项目；
2. 点击左侧导航栏中的 "CI/CD" -> "Pipelines"；
3. 查看构建任务执行状态与日志。

---

## 🎥 视频地址

[GitLab安装Runner](#)

---

## ❓ 常见问题

### Q: GitLab 中没有 CI/CD 入口？

- 确保 GitLab 版本为 14.0+；
- 确认 GitLab 配置中启用了 CI/CD 功能；
- 确保有足够的权限访问 CI/CD 设置。

---

### Q: Runner 启动失败或注册失败？

- 检查配置是否正确；
- 网络互通是否正常；
- 查看容器日志获取更多信息：

```bash
docker logs gitlab-runner
```

---

### Q: 如何升级 GitLab Runner？

可以通过重新拉取最新的镜像并重启容器：

```bash
docker stop gitlab-runner
docker rm gitlab-runner
docker pull gitlab/gitlab-runner:latest
# 然后重新运行启动命令
```

---

### Q: 如何查看 Runner 状态？

```bash
docker exec -it gitlab-runner gitlab-runner status
docker exec -it gitlab-runner gitlab-runner list
```

---

> 本节内容遵循 Apache 2.0 协议，欢迎引用与转载，需保留原始署名。