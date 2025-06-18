# Docker 容器的备份与恢复

> 本项目演示如何通过 `docker-compose` 启动两种挂载方式的 PostgreSQL 实例，并对其进行手动与自动化备份恢复操作。来演示 Docker 容器备份与恢复的实际操作。

## 🏗️ 容器配置

- `pg-volume`：使用 Docker 命名数据卷；
- `pg-bind`：使用宿主机目录挂载。
  
> 注：除非是不可变服务(即不产生数据的服务)，否则请使用上述两种操作(volume/bind)不要让容器自己维护数据

## 📦 初始化流程

1. 启动容器：

   ```bash
   docker-compose up -d
   ```

2. 分别执行 SQL 初始化（可通过客户端连接端口 5433/5434）：

   - `init/volume-init.sql`

     ```sql
     CREATE TABLE volume_table (key TEXT PRIMARY KEY, value TEXT);
     INSERT INTO volume_table VALUES ('volume_key', 'volume_value');
     ```

   - `init/bind-init.sql`

     ```sql
     CREATE TABLE bind_table (uuid UUID PRIMARY KEY, created_at TIMESTAMP);
     INSERT INTO bind_table VALUES (gen_random_uuid(), NOW());
     ```



---
> [SQL文件位置](./init/)

## 🛠️ 手动备份与恢复

### 手动备份

```bash
docker run --rm -v pgdata:/data -v $(pwd)/backup:/backup alpine tar -czvf /backup/pg-volume.tar.gz -C /data .
tar -czvf backup/pg-bind.tar.gz -C bind-mount/data .
```

### 清理环境

```bash
docker-compose down -v
```

### 手动恢复

```bash
docker-compose up -d
docker volume rm pgdata || true
docker volume create pgdata
docker run --rm -v pgdata:/data -v $(pwd)/backup:/backup alpine tar -xzvf /backup/pg-volume.tar.gz -C /data
tar -xzvf backup/pg-bind.tar.gz -C bind-mount/data/
```

---

## 🚀 一键自动备份与恢复

本项目提供了统一的自动化脚本，可通过配置文件批量备份与恢复多个容器的数据卷或挂载目录。

### 前置操作

安装 [yq](https://github.com/mikefarah/yq)：用于解析 YAML

```sh
sudo apt install yq
```

### 备份操作

```bash
chmod +x backup/backup-all.sh
./backup/backup-all.sh
```

该脚本会自动读取每个容器配置，分别将其数据打包保存到配置中指定的 `output_dir` 路径中。

---

### 恢复操作

```bash
chmod +x backup/restore-all.sh
./backup/restore-all.sh
```

恢复脚本会按照配置中指定的路径将数据恢复至原始位置（数据卷或宿主机目录），无需依赖 `docker-compose`，也无需容器处于运行状态。

---

## 🛠️ 配置文件（containers.yml）

位于 `backup/containers.yml`，用于定义需要备份/恢复的容器及其挂载方式：

```yaml
containers:
  - name: pg-volume
    type: volume
    source: pgdata
    backup_file: pg-volume.tar.gz
    output_dir: backup/volumes

  - name: pg-bind
    type: bind
    source: bind-mount/data
    backup_file: pg-bind.tar.gz
    output_dir: backup/binds
```

### 字段说明

| 字段名        | 说明                                   |
|---------------|----------------------------------------|
| `name`        | 容器标识（仅用于显示，无功能依赖）      |
| `type`        | 数据类型，支持 `volume` 或 `bind`       |
| `source`      | 卷名或宿主机挂载目录路径                |
| `backup_file` | 生成的备份文件名                        |
| `output_dir`  | 备份文件输出的目录（相对路径）          |

---

> 本项目遵循 Apache 2.0 协议，欢迎引用与修改。
