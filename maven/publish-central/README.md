# 发布到 Maven Central 教程

> 本节将指导你完成 **将 Kotlin/Java 项目发布到 Maven Central** 的实战流程，包括插件配置、密钥签名、凭证设置等关键步骤。

## 🎯 教程目标

- 本节你将学到：
  - 如何申请发布权限；
  - 如何生成并上传 GPG 签名密钥；
  - 如何配置 Gradle 发布插件；
  - 如何设置发布凭据；
  - 如何使用命令完成发布；
  - 如何验证发布成功。

## 📦 步骤说明

### 1. 环境准备

- 已注册 [Sonatype Central Portal](https://central.sonatype.com/account) 并获取发布 Token；
- 本地已安装 `gpg` 命令；
- 项目为 Gradle 管理的 Java/Kotlin 项目；
- 建议使用 Vanniktech 的 `maven-publish` 插件；
- 项目版本必须为正式版本（如 `1.0.0`），不能带 `-SNAPSHOT`。

### 2. 操作步骤

#### 2.1 注册权限并获取 Token

1. 访问 [Central Portal](https://central.sonatype.com/account)；
2. 登录后点击 `Access Tokens`，生成一个 Token；
3. 记录 `Username` 和 `Token` 用于后续发布配置。

> ✅ Token 用户名为一串短字符（如 `ukw9Jaax`），密码为 Token 值本体。

#### 2.2 生成并上传 GPG 密钥

1. 运行 `gpg --full-generate-key` 生成新密钥；
2. 使用默认配置，建议选择 RSA4096，永久有效；
3. 生成完成后运行：

   ```bash
   gpg --list-secret-keys --keyid-format LONG
   ```

4. 记录密钥 ID（如 `0BA08B3ACA55F0E3054C2D760D3FDAC82A9181EC`）；
5. 上传公钥到服务器：

   ```bash
   gpg --keyserver hkps://keys.openpgp.org --send-keys <你的KeyId>
   ```

> ✅ 建议同时备份 `.asc` 密钥，并导出私钥备用。

#### 2.3 配置 Gradle 插件与发布元数据

在每个要发布的模块中添加：

```kotlin
plugins {
    id("com.vanniktech.maven.publish") version "0.32.0"
}
```

添加发布配置：

```kotlin
mavenPublishing {
    publishToMavenCentral("DEFAULT", true)
    signAllPublications()
}
```

确保你设置了 `groupId`、`artifactId` 和 `version`：

```kotlin
group = "io.github.gewuyou"
version = "1.0.0" // 非 SNAPSHOT
```

#### 2.4 设置 GPG 签名密钥和 Central Token

将以下变量设置为环境变量或写入 `~/.gradle/gradle.properties`：

```properties
signing.keyId=你的GPGKeyId
signing.password=你的GPG密钥密码
signing.secretKey=-----BEGIN PGP PRIVATE KEY BLOCK-----
...你的私钥内容...
-----END PGP PRIVATE KEY BLOCK-----

mavenCentralUsername=你的Central用户名
mavenCentralPassword=你的Central Token
```

#### 2.5 执行发布命令

运行以下命令自动完成打包、签名与发布：

```bash
./gradlew publishAllPublicationsToMavenCentralRepository
```

发布成功后，稍等几分钟即可在 Maven Central 查看：

- https://central.sonatype.com/artifact/io.github.gewuyou/你的模块名

## ❓ 常见问题

### Q: 为什么我收到 401 错误？

请检查：

- 是否使用了 SNAPSHOT 版本（Central 不支持）；
- 是否仍引用了旧的 OSSRH URL；
- Token 用户名与密码是否设置为 Sonatype Central 的；

### Q: 我可以发布多个模块吗？

- 可以，建议每个子项目单独引入插件并继承根项目版本；
- Gradle 多模块发布完全兼容。

### Q: 签名失败怎么排查？

- 使用 `./gradlew signingReport` 检查密钥是否加载成功；
- 私钥格式必须为 ASCII（带有 `-----BEGIN ...`）；
- 私钥必须包含完整头尾。

---

> 本节内容遵循 Apache 2.0 协议，欢迎引用与转载，需保留原始署名。