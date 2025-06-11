# 高级配置与权限控制

> 本节将指导你完成 **Gitea 高级配置与访问权限控制** 的操作与实战演练，主要关注系统层级的配置与注册策略等高级功能。

## 🎯 教程目标

- 修改 Gitea 的关键配置项（`app.ini`）；
- 配置注册、登录策略与权限限制；
- 管理系统层级的功能（邮件、SSH、LFS 等）；
- 配置日志、索引、会话等服务。

## 📦 步骤说明

### 1. 环境准备

- 已安装并运行 Gitea；
- 使用管理员账户登录；
- 推荐先完成：[Gitea 的安装与基础配置](../install/README.md)

### 2. 系统配置项修改（app.ini）

- **配置文件位置**：
  - 如使用 Docker，通常位于 `~/docker/gitea/gitea/conf/app.ini`
- **编辑配置文件**：
  - 使用文本编辑器修改 `app.ini`，常见关键配置项如下（略）

- **修改后需重启容器**：

```bash
docker restart gitea
```

### 3. 注册与访问策略设置

- **禁止注册**：

  - 通过 `app.ini`：
    ```ini
    [service]
    DISABLE_REGISTRATION = true
    ```
  - 或通过后台页面：
    - 进入“管理后台” → “用户设置” → 勾选“禁止注册”

- **限制查看登录页前内容**：
    ```ini
    REQUIRE_SIGNIN_VIEW = true
    ```

- **开放 OpenID / OAuth / 邮件策略**：
  - 配置 `[openid]`、`[oauth2]`、`[mailer]` 等区块

### 4. 日志与调试配置

- 可设置：
  ```ini
  [log]
  MODE = file
  LEVEL = info
  ROOT_PATH = /data/gitea/log
  ```

### 5. 安全性建议

- 启用密码哈希：
  ```ini
  PASSWORD_HASH_ALGO = pbkdf2
  ```

- 开启安装锁、防止重复初始化：
  ```ini
  INSTALL_LOCK = true
  ```

## 🎥 视频地址

👉 敬请期待（录制完成后补充）

## ❓ 常见问题

### Q: 修改 `app.ini` 后没有生效？

请确保容器已正确重启，且未覆盖配置目录；
查看日志：`docker logs gitea` 获取启动信息。

### Q: 如何限制用户注册？

请参考 `[service]` 中 `DISABLE_REGISTRATION = true` 配置项，或通过管理后台设置。

### Q: OpenID 和 OAuth 如何配置？

启用 `[openid]` 和 `[oauth2]` 区块，并提供 JWT 密钥和相关服务配置。

---

> 本节内容遵循 Apache 2.0 协议，欢迎引用与转载，需保留原始署名。
