# GitLab安装Runner

> 本节将指导你完成 **安装 GitLab Runner** 的全过程

## 🎯 教程目标

- 本节你将学到：
  - 如何部署 GitLab Runner（基于 Docker）；
  - 如何注册 Runner 到 GitLab；
  - 如何编写 `.gitlab-ci.yml` 工作流文件；
  - 如何触发 CI/CD 流程；
  - 如何理解并部署不同类型的 Runner。

## 📦 步骤说明

### 1. 环境准备

- 已成功安装并运行 GitLab（建议版本 14.0 及以上）；
- GitLab 服务已开启 CI/CD 功能（默认开启）；
- 已创建一个普通项目用于测试 CI/CD。

### 2. 操作步骤

#### 2.1 安装

> 强烈推荐将 Runner 与 GitLab 分开部署，其中Runner最好使用docker-compose.yml来部署，方便维护。
>
> 注意本教程环境基于Linux,其它环境请请查阅[官方文档](https://docs.gitlab.com/runner/install)

##### 2.1.1 Linux 二进制安装

1. 添加官方 GitLab 仓库

   ```bash
   curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
   ```

2. 安装最新版本的 GitLab Runner，或跳过下一步安装特定版本

   ```bash
   # Debian/Ubuntu/Mint
   sudo apt install gitlab-runner
   # RHEL/CentOS/Fedora/Amazon Linux
   sudo yum install gitlab-runner
   #or
   sudo dnf install gitlab-runner
   ```

3. 要安装特定版本的 GitLab Runner

   ```bash
   # Debian/Ubuntu/Mint
   apt-cache madison gitlab-runner
   sudo apt install gitlab-runner=17.7.1-1 gitlab-runner-helper-images=17.7.1-1
   # RHEL/CentOS/Fedora/Amazon Linux
   yum list gitlab-runner --showduplicates | sort -r
   sudo yum install gitlab-runner-17.2.0-1
   ```

4. [注册一个Runner](https://docs.gitlab.com/runner/register/)

##### 2.1.2 Docker Compose安装(强烈推荐)

1. 创建Runner的Docker Compose文件

   ```yaml
   services:
     gitlab-runner-global-apple:
       image: gitlab/gitlab-runner:v18.0.2
       container_name: gitlab-runner-global-apple
       restart: always
       networks:
         - gitlab_default
       volumes:
         - ./runners/global/apple:/etc/gitlab-runner
         - /var/run/docker.sock:/var/run/docker.sock
     gitlab-runner-global-banana:
       image: gitlab/gitlab-runner:v18.0.2
       container_name: gitlab-runner-global-banana
       restart: always
       networks:
         - gitlab_default
       volumes:
         - ./runners/global/banana:/etc/gitlab-runner
         - /var/run/docker.sock:/var/run/docker.sock
   networks:
     gitlab_default:
       external: true
   ```

   请注意- ./runners/xxx/xxx:/etc/gitlab-runner

   这个是将runner的配置挂载到宿主机目录，可以将配置挂载到一个路径，这将合并所有配置，相当于集中管理，看个人喜好

   文件名看喜好，一般是docker-compose.yml

2. 启动Runner服务

   ```bash
   docker compose -f docker-compose.yml up -d
   ```

3. [注册一个Runner](https://docs.gitlab.com/runner/register/)

---

#### 2.2 注册 Runner 到 GitLab

##### 2.2.1 Runner 介绍

Runner 启动后，需要注册到 GitLab 实例才能使用。

对于Runner来说一共有三种分别为实例级、群组级、项目级

实例级Runner一般是作为通用Runner，一般在gitlab中项目技术栈不复杂且项目不多时推荐使用，因为它能够被所有项目继承。

群组级Runner一般是作为群组通用Runner，对于不同的技术栈可以通过tag区分

项目级Runner一般是作为项目定制的Runner，适用于特殊项目，粒度最细

![image-20251217105339131](README.assets/image-20251217105339131.png)

参考链接

[什么是 Runner？](https://docs.gitlab.com/runner/)

##### 2.2.2 Runner 注册

> 这里以实例Runner作为示例，请注意，这需要用户拥有管理员权限。

###### 2.2.2.1 进入Runner注册页面

- 点击左上角Icon进入首页
- 点击侧边栏的管理员按钮
- 点击左侧 CI/CD -> Runner 
- 点击右上角的创建实例Runner按钮

![image-20251217110054927](README.assets/image-20251217110054927.png)

###### 2.2.2.2 配置注册信息

- 标签用来区分runner的环境，这里统一假设runner是基于Docker运行的，并设置了运行时镜像
- 比如Runner的运行时镜像中有Maven，Java，那标签可以统一打上maven,java，这样可以用来匹配runner
- 当然如果gitlab上项目技术栈单一可以直接让runner运行未打标签的作业，不过这个一般不推荐
- 描述，顾名思义
- 最大作业超时，即Runner 在结束前可以运行的最大时间。 如果一个项目的任务超时时间较短，则使用实例 Runner 的任务超时时间。
- 一般1小时或者10小时都行，看项目标准构建时长基于此上下浮动，防止作业卡住长时间占用Runner

![image-20251217110730311](README.assets/image-20251217110730311.png)

比如像我这样，我的运行时容器有node，有docker，有git，因此我加上了这些标签，超时我设置为1h，接着点击创建 runner 即可

###### 2.2.2.3 注册Runner

- 当点击按钮后应该会进入注册页面

  ![image-20251217111411036](README.assets/image-20251217111411036.png)

- 这里无论是二进制还是Docker，其实默认Linux即可

- 对于二进制，直接在服务器上执行注册命令即可，对于Docker，进入runner的docker终端执行注册命令即可

- 按照提示输入以下信息：
  - GitLab 实例 URL（左侧展示默认的，这里看完没问题，直接回车就行了）
  - Runner名称 （同上，你也可以用你自定义的名称）
  - 选择执行器类型（通常选择 docker）

  - 输入默认Docker镜像名称（这里看你自己的运行时镜像名称是什么，输入即可）

  - 输入后，应该就创建成功了，这里用的是docker执行器，其它类型略有不同


###### 2.2.2.4 自定义runner配置

注册完成后，需要配置 Runner 使用 Docker 执行器来运行作业。

请注意，对于Docker Compose部署的Runner，可以在文件挂载的路径中找到

对于二进制安装注册的Runner，请访问/etc/gitlab-runner，所有runner的配置都在里面

一个runner配置包含类似内容（实际可能更多）：

```toml
[[runners]]
  name = "my-runner"
  id = 1
  url = "http://gitlab.example.com/"
  token = "your-token"
  executor = "docker"
  [runners.cache]
   MaxUploadedArchiveSize = 0
   [runners.cache.s3]
   [runners.cache.gcs]
   [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    # 这里很重要，需要将宿主机的docker和runner的docker关联
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
    pull_policy = ["if-not-present"]
    shm_size = 0
    # 这里也很重要需要指定helper_image
    helper_image = "gitlab/gitlab-runner-helper:x86_64-v[你的gitlab版本]"
```

配置完保存即可

对于二进制安装的，请运行

```bash
sudo systemctl restart gitlab-runner
```

对于Docker安装的，直接重启容器就行了

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

### 3. 查看执行状态

1. 打开 GitLab 项目；
2. 点击左侧导航栏中的 "CI/CD" -> "Pipelines"；
3. 查看构建任务执行状态与日志。

---

## 🎥 视频地址

敬请期待

---

## ❓ 常见问题

### Q: GitLab 中没有 CI/CD 入口？

- 确保 GitLab 版本为 14.0+；
- 确认 GitLab 配置中启用了 CI/CD 功能；
- 确保有足够的权限访问 CI/CD 设置。

---

> 本节内容遵循 Apache 2.0 协议，欢迎引用与转载，需保留原始署名。