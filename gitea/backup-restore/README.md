# Docker 下的 Gitea 的备份与恢复

> 本节将指导你完成在 **Docker 环境中 Gitea 的备份与恢复** 的相关操作与实战演练。

## 🎯 教程目标

- 本节你将学到：
  - 如何备份 Gitea 的数据和数据库；
  - 如何通过 Gitea 提供的命令行工具进行备份；
  - 如何恢复完整的 Gitea 实例；
  - 如何挂载和管理持久化数据卷。

## 📦 步骤说明

### 1. 环境准备

- 已成功使用 Docker Compose 安装并运行 Gitea；
- 本文假设你使用如下目录结构：

```bash
~/docker/gitea/
├── docker-compose.yml
├── gitea/         # Gitea 数据目录挂载点（/data）
└── gitea-db/      # PostgreSQL 数据库目录挂载点
```

### 2. 操作步骤

#### 2.1 使用 Gitea 自带命令备份

进入 Gitea 容器并执行备份命令：

```bash
docker exec -u 1000 -it gitea bash
gitea dump -c /data/gitea/conf/app.ini
```

执行成功后将在 `/data/gitea` 目录生成一个形如：

```bash
gitea-dump-2025-06-06T12-34-56.zip
```

退出容器后，可复制该文件到宿主机：

```bash
docker cp gitea:/data/gitea/gitea-dump-2025-06-06T12-34-56.zip .
```

> ✅ 此备份文件包含数据库、仓库、配置等完整数据。

#### 2.2 手动备份数据卷（推荐搭配使用）

你也可以直接备份挂载目录（冷备份）：

```bash
cd ~/docker
tar -czvf gitea-backup.tar.gz gitea
```

此方式适合整体迁移或灾难恢复。

#### 2.3 恢复 Gitea 实例

##### 方式一：使用 `gitea dump` 生成的压缩包恢复

1. 重新部署 Gitea（可参考安装章节）；
2. 将 `gitea-dump-xxx.zip` 放入容器数据目录 `/data/gitea`；
3. 进入容器后执行恢复命令：

```bash
gitea restore -c /data/gitea/conf/app.ini --file /data/gitea/gitea-dump-xxx.zip
```

> 注意：恢复前请确保容器初始状态干净。

##### 方式二：恢复数据卷（简单可靠）

1. 停止当前容器：

    ```bash
    cd ~/docker/gitea
    docker-compose down
    ```

2. 解压之前备份的数据卷：

    ```bash
    cd ~/docker
    tar -xzvf gitea-backup.tar.gz
    ```

3. 替换当前的 `gitea/` 与 `gitea-db/` 目录（若已有则覆盖）；

4. 重新启动服务：

```bash
cd ~/docker/gitea
docker-compose up -d
```

### 🔒 权限注意事项

- 确保恢复后的目录仍归属 `UID=1000`；
- 可进入容器并修复权限：

```bash
docker exec -it gitea chown -R 1000:1000 /data
```

## 🎥 视频地址

👉 敬请期待（录制完成后补充）

## ❓ 常见问题

### Q: 恢复后访问 Gitea 报错或页面异常？

- 检查权限是否正确；
- 删除旧缓存 `rm -rf /data/gitea/indexers`；
- 尝试重启容器。

### Q: 可以只恢复某一个仓库吗？

- `gitea dump` 是整体备份；
- 若需单独恢复，请使用 Git 操作拉取仓库。

---

> 本节内容遵循 Apache 2.0 协议，欢迎引用与转载，需保留原始署名。
