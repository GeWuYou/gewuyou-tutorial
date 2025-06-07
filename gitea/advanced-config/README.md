# 高级配置与权限控制

> 本节将指导你完成 **高级配置与权限控制** 的相关操作与实战演练。

## 🎯 教程目标

- 本节你将学到：
  - 如何修改 Gitea 的关键配置项；
  - 如何管理组织、团队与成员权限；
  - 如何设置仓库访问权限与协作者角色；
  - 如何限制注册与开放策略。

## 📦 步骤说明

### 1. 环境准备

- 已成功安装并运行 Gitea 实例；
- 使用管理员账户登录；
- 参考：[Gitea 的安装与基础配置](../install/README.md)

### 2. 操作步骤

#### 2.1 修改系统配置（app.ini）

1. 通过 Web 界面查看
   1. 进入 "管理面板"（通常位于左侧菜单底部）。
   2. 在管理面板中，可以找到多个配置选项，如应用设置、数据库设置、邮件服务设置等。
2. 通过配置文件修改
   1. 找到 Gitea 的配置文件 app.ini
   2. 其位置取决于你的安装方式：如果使用默认安装路径，通常可以在 $HOME/.gitea/ 或 /etc/gitea/ 下找到。参考之前的教程：[Gitea 的安装与基础配置](../../gitea/install/README.md)可以知道位置在  `~/docker/gitea/gitea/conf/app.ini`。
   3. 使用文本编辑器打开 app.ini 文件，该文件分为多个部分，每个部分代表不同的配置项。
   4. 这是一个参考的配置文件，你可以根据需要修改。(请注意不要照搬，请参考整个配置来修改你的配置)

    ```ini
        APP_NAME = Gitea: Git with a cup of tea  # 应用名称
        RUN_MODE = prod  # 运行模式，生产环境
        RUN_USER = git  # 运行用户
        WORK_PATH = /data/gitea  # 工作目录
        
        [repository]
        ROOT = /data/git/repositories  # 仓库根目录
        
        [repository.local]
        LOCAL_COPY_PATH = /data/gitea/tmp/local-repo  # 本地仓库的临时存储路径
        
        [repository.upload]
        TEMP_PATH = /data/gitea/uploads  # 上传文件的临时存储路径
        
        [server]
        APP_DATA_PATH = /data/gitea  # 应用数据存储路径
        DOMAIN = 172.21.235.129  # 服务器域名或IP
        SSH_DOMAIN = 172.21.235.129  # SSH 域名或IP
        HTTP_PORT = 3000  # HTTP 端口
        ROOT_URL = http://172.21.235.129:3100/  # Gitea 访问的根 URL
        DISABLE_SSH = false  # 是否禁用 SSH
        SSH_PORT = 22  # SSH 端口
        SSH_LISTEN_PORT = 22  # SSH 监听端口
        LFS_START_SERVER = true  # 启动 LFS 服务
        LFS_JWT_SECRET = 5uEhPtubh9FM5uq_c2nm5yfFcDF6MGjgZ9EAUSG5r1k  # LFS JWT 密钥
        OFFLINE_MODE = true  # 是否启用离线模式
        
        [database]
        PATH = /data/gitea/gitea.db  # 数据库文件存储路径
        DB_TYPE = postgres  # 数据库类型
        HOST = gitea-db:5432  # 数据库主机与端口
        NAME = gitea  # 数据库名称
        USER = gitea  # 数据库用户
        PASSWD = s1tGsUUMAWLq  # 数据库密码
        LOG_SQL = false  # 是否记录 SQL 查询日志
        SCHEMA =  # 数据库模式
        SSL_MODE = disable  # SSL 模式，禁用 SSL
        
        [indexer]
        ISSUE_INDEXER_PATH = /data/gitea/indexers/issues.bleve  # 问题索引存储路径
        
        [session]
        PROVIDER_CONFIG = /data/gitea/sessions  # 会话存储配置路径
        PROVIDER = file  # 会话提供者，使用文件存储
        
        [picture]
        AVATAR_UPLOAD_PATH = /data/gitea/avatars  # 用户头像上传路径
        REPOSITORY_AVATAR_UPLOAD_PATH = /data/gitea/repo-avatars  # 仓库头像上传路径
        
        [attachment]
        PATH = /data/gitea/attachments  # 附件存储路径
        
        [log]
        MODE = console  # 日志模式，输出到控制台
        LEVEL = info  # 日志级别，信息级别
        ROOT_PATH = /data/gitea/log  # 日志文件存储路径
        
        [security]
        INSTALL_LOCK = true  # 安装锁，确保安装后不能重复安装
        SECRET_KEY =  # 应用秘钥，通常用于加密等操作
        REVERSE_PROXY_LIMIT = 1  # 反向代理的限制
        REVERSE_PROXY_TRUSTED_PROXIES = *  # 反向代理的信任代理地址
        INTERNAL_TOKEN = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.bqmkXk8lANgsRxA7BrCC6PnD0i3TFB4pAAjNJAljKMo  # 内部 token
        PASSWORD_HASH_ALGO = pbkdf2  # 密码哈希算法，使用 PBKDF2
        
        [service]
        DISABLE_REGISTRATION = true  # 禁用用户注册
        REQUIRE_SIGNIN_VIEW = false  # 是否强制查看登录界面
        REGISTER_EMAIL_CONFIRM = false  # 是否需要邮件确认注册
        ENABLE_NOTIFY_MAIL = false  # 是否启用邮件通知
        ALLOW_ONLY_EXTERNAL_REGISTRATION = false  # 是否只允许外部注册
        ENABLE_CAPTCHA = false  # 是否启用验证码
        DEFAULT_KEEP_EMAIL_PRIVATE = false  # 是否默认将邮箱保持私密
        DEFAULT_ALLOW_CREATE_ORGANIZATION = true  # 是否允许用户创建组织
        DEFAULT_ENABLE_TIMETRACKING = true  # 是否启用时间追踪
        NO_REPLY_ADDRESS = noreply.localhost  # 默认的无回复邮件地址
        
        [lfs]
        PATH = /data/git/lfs  # LFS 存储路径
        
        [mailer]
        ENABLED = false  # 是否启用邮件服务
        
        [openid]
        ENABLE_OPENID_SIGNIN = true  # 是否启用 OpenID 登录
        ENABLE_OPENID_SIGNUP = true  # 是否启用 OpenID 注册
        
        [cron.update_checker]
        ENABLED = ture  # 是否启用定期更新检查
        
        [repository.pull-request]
        DEFAULT_MERGE_STYLE = merge  # 默认合并样式
        
        [repository.signing]
        DEFAULT_TRUST_MODEL = committer  # 默认的签名信任模型
        
        [oauth2]
        JWT_SECRET = SwnNbeHhnNOBQH5ah3ZQiOr6kb_t0D4rTTm5mRqlXwI  # OAuth2 的 JWT 秘钥
    ```

3. 修改完成后重启容器：

```bash
docker restart gitea
```

> 注意：修改配置文件需在 Gitea 启动后初始化生成或手动挂载配置卷。

#### 2.2 组织与团队管理

1. 登录 Gitea 后，点击右上角头像 → “新建组织”；
2. 填写组织名称，例如：`dev-org`；
3. 创建成功后，进入组织首页；
4. 点击“团队”标签页 → “新建团队”；
5. 创建不同类型的团队（开发者、维护者等）；
6. 添加用户到对应团队。

#### 2.3 设置仓库访问权限

1. 在组织页面点击“新建仓库”，创建组织内仓库；
2. 创建后进入“设置” → “协作者与团队”；
3. 添加团队并设置权限（读取 / 写入 / 管理）；
4. 添加个人协作者（非组织成员也可添加）。

#### 2.4 账户注册控制

如你希望关闭公开注册：

- 方法一：修改 `app.ini` 中 `[service]` 部分：

```ini
DISABLE_REGISTRATION = true
```

- 方法二：后台页面设置：
  - 进入“管理后台” → “用户设置”；
  - 勾选“禁止注册”选项；
  - 可选开启“管理员审核注册”。

## 🎥 视频地址

👉 敬请期待（录制完成后补充）

## ❓ 常见问题

### Q: 修改 `app.ini` 后没有生效？

请确保容器已正确重启，且未覆盖配置目录；
查看日志：`docker logs gitea` 获取启动信息。

### Q: 如何为团队赋予仓库权限？

进入仓库 → 设置 → 协作者与团队 → 添加团队并设置访问级别。

### Q: 用户可以访问所有仓库吗？

默认情况下，公开仓库所有人可见，私有仓库仅限成员访问；
可以通过组织或团队进行权限精细化控制。

---

> 本节内容遵循 Apache 2.0 协议，欢迎引用与转载，需保留原始署名。
