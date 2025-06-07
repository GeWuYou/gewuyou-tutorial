# 创建用户与代码仓库

> 本节将指导你完成 **创建用户与代码仓库** 的相关操作与实战演练。

## 🎯 教程目标

- 本节你将学到：
  - 如何在 Gitea 中创建新用户；
  - 如何为用户分配权限；
  - 如何创建新的代码仓库；
  - 如何通过 Git 操作远程仓库。
  - 如何修改 Gitea 的配置文件。

## 📦 步骤说明

### 1. 环境准备

确保你已经成功运行并访问 Gitea 服务，参考上一章节：[Gitea 的安装与基础配置](../../gitea/install/README.md)

- 确保你可以通过 [http://localhost:3001](http://localhost:3001) 正常访问 Gitea；
- 本节以管理员账户登录进行演示。

### 2. 操作步骤

#### 2.1 创建新用户

1. 以管理员身份登录 Gitea；
2. 右上角点击头像 → 管理后台；
3. 点击左侧菜单栏的 “用户管理”；
4. 点击右上角的 “新建账户”；
5. 填写新用户信息：
   - 用户名：`devuser`
   - 邮箱：`dev@example.com`
   - 密码：自定义
6. 点击 “创建账户” 完成。

> ✅ 你现在已经创建了一个普通用户 `devuser`。

#### 2.2 切换用户登录

1. 退出管理员账号；
2. 使用 `devuser` 登录；
3. 登录成功后，进入用户首页。

#### 2.3 创建代码仓库

1. 点击右上角 ➕ → “新建仓库”；
2. 仓库名称示例：`demo-repo`；
3. 可选设置：
   - 描述：一个用于演示的仓库
   - 私有仓库：可根据需要开启
   - 初始化仓库：勾选 “README 文件”
4. 点击 “创建仓库”。

> ✅ 你现在已经创建了第一个仓库。

#### 2.4 本地 Git 操作示例

确保你已安装 Git 工具：

```bash
git clone http://localhost:3001/devuser/demo-repo.git
cd demo-repo
echo "# Hello Gitea" > hello.md
git add .
git commit -m "init: add hello.md"
git push origin main
```

你现在可以回到 Gitea 页面，刷新仓库页面看到你刚刚提交的内容。

#### 2.5 查看并修改 Gitea 的配置

1. 通过 Web 界面查看
   1. 进入 "管理面板"（通常位于左侧菜单底部）。
   2. 在管理面板中，可以找到多个配置选项，如应用设置、数据库设置、邮件服务设置等。
2. 通过配置文件修改
   1. 找到 Gitea 的配置文件 app.ini
   2. 其位置取决于你的安装方式：如果使用默认安装路径，通常可以在 $HOME/.gitea/ 或 /etc/gitea/ 下找到。参考之前的教程：[Gitea 的安装与基础配置](../../gitea/install/README.md)可以知道位置在  `~/docker/gitea/gitea/conf/app.ini`。
   3. 使用文本编辑器打开 app.ini 文件，该文件分为多个部分，每个部分代表不同的配置项。
   4. 这是一个参考的配置文件，你可以根据需要修改。(请注意不要照搬，请参考整个配置来修改你的配置)

      - ```ini
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

## 🎥 视频地址

👉 敬请期待（录制完成后补充）

## ❓ 常见问题

### Q: 创建用户时提示邮箱已存在？

请确认该邮箱未被注册；若已注册，可尝试使用其他邮箱地址。

### Q: 无法推送代码？

请检查是否启用了 Gitea 的 SSH 或 HTTP 推送方式；
也可以进入仓库页面，点击 "Clone" 查看正确的远程地址。

---

> 本节内容遵循 Apache 2.0 协议，欢迎引用与转载，需保留原始署名。
