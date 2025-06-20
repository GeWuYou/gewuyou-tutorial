# Docker 容器的备份与恢复

> 本节教程将通过 `docker-compose` 启动两种挂载方式的 PostgreSQL 实例，并演示其手动与简单自动化的备份与恢复流程，帮助你掌握容器数据持久化的实际操作方法。

## 🏗️ 容器配置

- `数据卷(volume)`：使用 Docker 命名卷来管理容器数据；
- `绑定挂载（bind mount）`：将宿主机目录挂载到容器内部。

> 📌 **提示**：除非容器是无状态服务（即不产生持久数据），否则应始终使用 `volume` 或 `bind` 挂载方式来管理数据。切勿依赖容器自身内部目录持久化数据，以避免数据在容器销毁时丢失。

## 📦 初始化流程

1. 启动容器：

   ```bash
   docker-compose up -d
   ```

   对应脚本：

   ```yml
   version: '3.8'
   services:
     pg-volume:
       image: postgres:16
       container_name: pg-volume
       environment:
         POSTGRES_PASSWORD: password
         POSTGRES_DB: volumedb
       volumes:
         - pgdata:/var/lib/postgresql/data
       ports:
         - "5433:5432"
   
     pg-bind:
       image: postgres:16
       container_name: pg-bind
       environment:
         POSTGRES_PASSWORD: password
         POSTGRES_DB: binddb
       volumes:
         - ./bind-mount/data:/var/lib/postgresql/data
       ports:
         - "5434:5432"
   volumes:
     pgdata:
       # 备份时，如果是先创建数据卷，请开启此项，如果是先创建容器，请注释此项
       # external: true
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
# 对命名卷 pgdata 进行打包（静默模式）
docker run --rm \
  -v  backup-and-restore_pgdata:/data \
  -v "$(pwd)/backup":/backup \
  alpine \
  tar -czf /backup/pg-volume.tar.gz -C /data .
# 对 bind-mount 的目录进行本地打包（静默）
tar -czf ./backup/pg-bind.tar.gz -C bind-mount/data .
```

### 清理环境

```bash
docker-compose down -v
```

### 手动恢复

```bash
# 清理并重建名为 pgdata 的数据卷
docker volume rm pgdata || true
docker volume create pgdata

# 恢复 pgdata 卷（静默模式，不输出文件列表）
docker run --rm \
  -v pgdata:/data \
  -v "$(pwd)/backup":/backup \
  alpine \
  tar -xzf /backup/pg-volume.tar.gz -C /data
# 确保挂载目录存在
mkdir -p ./bind-mount/data

# 恢复 bind 挂载目录（静默）
tar -xzf ./backup/pg-bind.tar.gz -C ./bind-mount/data/

# 启动容器（例如数据库服务）
docker-compose up -d
```

---

## 🚀 一键自动备份与恢复

本项目提供了统一的自动化脚本，可通过配置文件批量备份与恢复多个容器的数据卷或挂载目录。

### 前置操作

安装 [yq](https://github.com/mikefarah/yq)：用于解析 YAML

```sh
apt-get update
sudo apt install yq
```

### 备份操作

```bash
chmod +x ./backup-all.sh
./backup-all.sh
```

备份脚本

```sh
#!/bin/bash
set -e

# =============================================================================
# 脚本名称: backup-all.sh
# 功能描述: 从配置文件 containers.yml 中读取容器备份信息，执行全量容器数据备份操作
# 使用方法: 
# 1. 确保 containers.yml 配置文件存在且配置正确
# 2. 执行脚本: bash backup-all.sh
# 输出说明: 会在当前目录生成或更新 all-backup.tar.gz 备份文件
# 注意：本脚本只是一个简单的自动脚本，请根据实际情况进行修改。
# =============================================================================
# 免责声明：
# 使用本脚本前请仔细阅读并同意以下免责声明：
# 1. 本脚本仅供参考，并不保证完全适用于所有环境，使用者需自行承担风险。
# 2. 本脚本会执行容器数据备份操作，可能会影响容器和数据卷的状态，请确保在安全环境中使用。
# 3. 请确保已备份所有重要数据，操作前请务必验证配置文件 `containers.yml` 是否正确。
# 4. 本脚本执行备份时，默认不会覆盖现有备份文件，除非手动删除。请在执行备份前做好确认。
# 5. 本脚本提供交互式清理选项，用户应谨慎操作，确保不会误删数据。
# 6. 使用本脚本时，用户应自行负责所有操作的后果，作者不对因使用本脚本导致的任何损失或损害负责。

# ==============================================================================
# 函数定义: cleanup_files
# 功能:     交互式清理备份临时文件和归档文件
# 参数:     无
# 返回值:   无
# ==============================================================================
function cleanup_files {
  read -rp "🧹 Do you want to delete the '$BACKUP_ROOT' folder now? (y/n): " cleanup
  case "$cleanup" in
    y|Y)
      rm -rf "$BACKUP_ROOT"
      rm -f all-backup.tar.gz
      echo "✅ Cleanup completed."
      ;;
    n|N)
      echo "🗂️  '$BACKUP_ROOT' folder retained."
      ;;
    *)
      echo "⚠️ Invalid input. Please enter y or n."
      cleanup_files  # 递归调用重试
      ;;
  esac
}

# 读取配置文件路径和备份根目录
CONFIG_FILE="./containers.yml"
BACKUP_ROOT=$(yq '.config[0].backup_root' "$CONFIG_FILE")  # 默认读取 containers.yml 配置的根目录
# 去除从YAML文件中读取的值中的引号
BACKUP_ROOT=${BACKUP_ROOT//\"/}
echo "📦 Loading configuration from $CONFIG_FILE..."

# 获取容器数量
containers=$(yq '.containers | length' "$CONFIG_FILE")
echo "📦 Total containers: $containers"

# 主要处理逻辑：遍历所有容器进行备份操作
# 包含以下核心步骤：
# 1. 读取容器配置信息
# 2. 格式化配置参数
# 3. 创建备份目录结构
# 4. 自动检测 volume 名（优先 source，fallback 使用 container）
# 5. 执行容器数据备份
for i in $(seq 0 $((containers - 1))); do
  # 获取容器配置信息
  name=$(yq ".containers[$i].name" "$CONFIG_FILE")
  type=$(yq ".containers[$i].type" "$CONFIG_FILE")
  source=$(yq ".containers[$i].source" "$CONFIG_FILE")
  backup_file=$(yq ".containers[$i].backup_file" "$CONFIG_FILE")
  output_dir=$(yq ".containers[$i].output_dir" "$CONFIG_FILE")

  # 去除引号并转换类型为小写
  name=${name//\"/}
  type=${type//\"/}
  source=${source//\"/}
  backup_file=${backup_file//\"/}
  output_dir=${output_dir//\"/}
  type=$(echo "$type" | tr 'A-Z' 'a-z')

  # 确保备份输出目录存在，并以 `backup` 为根目录
  backup_target_dir="$BACKUP_ROOT$output_dir"

  # 创建备份目录结构
  mkdir -p "$backup_target_dir"

  # 自动检测 volume 名（优先 source，fallback 使用 container）
  if [[ "$type" == "volume" && -z "$source" && "$container" != "none" ]]; then
    echo "🔍 Auto-detecting volume from container: $container"
    source=$(docker inspect "$container" 2>/dev/null | jq -r '.[0].Mounts[] | select(.Type == "volume") | .Name')
    if [[ -z "$source" ]]; then
      echo "❌ No volume found in container [$container]"
      continue
    fi
  fi

  if [[ "$type" == "volume" && -z "$source" ]]; then
    echo "❌ Missing volume source for [$name], please specify it in config."
    continue
  fi

  echo "🔄 Backing up [$name] → $backup_target_dir/$backup_file (type: $type)"

  # 执行容器数据备份操作
  # 支持两种类型的备份：volume 和 bind
  if [[ "$type" == "volume" ]]; then
    docker run --rm \
      -v "$source":/data \
      -v "$(pwd)/$backup_target_dir":/backup \
      alpine \
      tar -czf "/backup/$backup_file" -C /data .
  elif [[ "$type" == "bind" ]]; then
    if [[ -d "$source" ]]; then
      tar -czf "$backup_target_dir/$backup_file" -C "$source" .
    else
      echo "❌ Source directory not found for [$name]: $source"
    fi
  else
    echo "❌ Unknown type [$type] for [$name]"
  fi
done

# 打包 backup 目录为归档
# 生成最终的备份归档文件 all-backup.tar.gz
tar -czf all-backup.tar.gz -C ./ $BACKUP_ROOT
echo "✅ All backups completed. Archive: all-backup.tar.gz"

# 调用清理函数
# 提供交互式清理选项，用户可以选择是否删除临时备份文件
cleanup_files

```

该脚本会自动读取每个容器配置，分别将其数据打包保存到配置中指定的 `output_dir` 路径中。

---

### 恢复操作

```bash
chmod +x ./restore-all.sh
./restore-all.sh
```

恢复脚本

```sh
#!/bin/bash
set -e

# =============================================================================
# 脚本名称: restore-all.sh
# 作用: 从备份中恢复Docker容器数据
# 描述: 该脚本会根据containers.yml配置文件中的定义,从备份文件中恢复Docker容器数据。
#         支持两种恢复类型:
#         1. volume: 恢复到Docker卷
#         2. bind: 恢复到主机目录
# 使用方法:
# 1. 确保当前目录下有containers.yml配置文件，其中定义了需要恢复的容器信息
# 2. 将备份文件放在指定的输出目录中
# 3. 运行脚本: ./restore-all.sh
# 4. 如果有all-backup.tar.gz压缩包，脚本会自动解压
# 5. 脚本执行完成后，会提示是否清理备份文件
# 注意：本脚本只是一个简单的自动脚本，请根据实际情况进行修改。
# =============================================================================
# 免责声明：
# 使用本脚本前请仔细阅读并同意以下免责声明：
# 1. 本脚本仅供参考，并不保证完全适用于所有环境，使用者需自行承担风险。
# 2. 本脚本会执行容器数据恢复操作，可能会影响容器和数据卷的状态，请确保在安全环境中使用。
# 3. 请确保已备份所有重要数据，操作前请务必验证配置文件 `containers.yml` 是否正确。
# 4. 本脚本提供恢复选项，用户应谨慎操作，确保不会误删除或覆盖数据。
# 5. 使用本脚本时，用户应自行负责所有操作的后果，作者不对因使用本脚本导致的任何损失或损害负责。

# 定义配置文件路径和备份根目录
CONFIG_FILE="./containers.yml"
BACKUP_ROOT=$(yq '.config[0].backup_root' "$CONFIG_FILE")  # 默认读取 containers.yml 配置的根目录
# 去除引号并转换类型为小写
BACKUP_ROOT=${BACKUP_ROOT//\"/}
echo "📦 Loading configuration from $CONFIG_FILE..."

# 如果检测到all-backup.tar.gz压缩包，则解压该文件
if [[ -f "./all-backup.tar.gz" ]]; then
  echo "📦 Found archive all-backup.tar.gz, extracting..."
  tar -xzf all-backup.tar.gz
fi

# 获取需要恢复的容器总数
containers=$(yq '.containers | length' "$CONFIG_FILE")
echo "📦 Total containers: $containers"

# 遍历每个容器并执行恢复操作
for i in $(seq 0 $((containers - 1))); do
  # 从配置文件中获取容器的各个属性
  name=$(yq ".containers[$i].name" "$CONFIG_FILE")
  type=$(yq ".containers[$i].type" "$CONFIG_FILE")
  source=$(yq ".containers[$i].source" "$CONFIG_FILE")
  backup_file=$(yq ".containers[$i].backup_file" "$CONFIG_FILE")
  output_dir=$(yq ".containers[$i].output_dir" "$CONFIG_FILE")
  restore_target=$(yq ".containers[$i].restore_target" "$CONFIG_FILE" 2>/dev/null || echo "")

  # 去除从YAML文件中读取的值中的引号
  name=${name//\"/}
  type=${type//\"/}
  source=${source//\"/}
  backup_file=${backup_file//\"/}
  output_dir=${output_dir//\"/}
  restore_target=${restore_target//\"/}
  type=$(echo "$type" | tr 'A-Z' 'a-z')

    # 确保备份输出目录存在，并以 `backup` 为根目录
  backup_target_dir="$BACKUP_ROOT$output_dir"
  echo "♻️ Restoring [$name] from $backup_target_dir/$backup_file (type: $type)"

  # 检查备份文件是否存在
  if [[ ! -f "$backup_target_dir/$backup_file" ]]; then
    echo "❌ Backup file not found: $backup_target_dir/$backup_file"
    continue
  fi

  # 根据容器类型执行不同的恢复操作
  if [[ "$type" == "volume" ]]; then
    # 处理volume类型的恢复
    if [[ -z "$source" ]]; then
      echo "❌ Volume [$name] missing required 'source' (volume name), please add it in config."
      continue
    fi

    echo "🔁 Recreating volume: $source"
    docker volume rm "$source" >/dev/null 2>&1 || true
    docker volume create "$source"

    docker run --rm \
      -v "$source":/data \
      -v "$(pwd)/$BACKUP_ROOT$output_dir":/backup \
      alpine \
      tar -xzf "/backup/$backup_file" -C /data

  elif [[ "$type" == "bind" ]]; then
    # 处理bind类型的恢复
    target_path="$source"
    if [[ -n "$restore_target" && "$restore_target" != "null" ]]; then
      target_path="$restore_target"
      echo "📁 Overriding restore target: $target_path"
    fi

    # 如果目标目录存在则清空，否则创建新目录
    if [[ -d "$target_path" ]]; then
      echo "🧹 Cleaning target bind directory: $target_path"
      rm -rf "$target_path"/*
    else
      echo "📁 Creating target bind directory: $target_path"
      mkdir -p "$target_path"
    fi

    # 执行实际的文件恢复操作
    tar -xzf "$backup_target_dir/$backup_file" -C "$target_path"

  else
    echo "❌ Unknown type [$type] for [$name]"
  fi
done

# 智能清理提示部分
# 创建要清理的目标列表
cleanup_targets=()
[[ -d "$BACKUP_ROOT" ]] && cleanup_targets+=("$BACKUP_ROOT folder")
[[ -f "all-backup.tar.gz" ]] && cleanup_targets+=("all-backup.tar.gz archive")

# 如果没有可清理的目标，直接退出
if [[ ${#cleanup_targets[@]} -eq 0 ]]; then
  echo "📁 Nothing to clean up."
  exit 0
fi

# 显示清理确认提示
echo -n "🧹 Do you want to delete the "
for ((j = 0; j < ${#cleanup_targets[@]}; j++)); do
  if [[ $j -gt 0 ]]; then
    echo -n " and "
  fi
  echo -n "${cleanup_targets[$j]}"
done
echo "? (y/n)"

# 用户确认清理操作
while true; do
  read -rp "➤ Your choice: " confirm_cleanup
  case "$confirm_cleanup" in
    y|Y)
      [[ -d "$BACKUP_ROOT" ]] && rm -rf "$BACKUP_ROOT"
      [[ -f "all-backup.tar.gz" ]] && rm -f all-backup.tar.gz
      echo "✅ Cleanup completed."
      break
      ;;
    n|N)
      echo "📁 Files retained."
      break
      ;;
    *)
      echo "⚠️ Please enter y or n."
      ;;
  esac
done
```

恢复脚本会按照配置中指定的路径将数据恢复至原始位置（数据卷或宿主机目录），无需依赖 `docker-compose`，也无需容器处于运行状态。

---

## 🛠️ 配置文件（containers.yml）

位于 `./containers.yml`，用于定义需要备份/恢复的容器及其挂载方式：

```yaml
# 容器备份配置列表
# 每个条目定义了一个容器的备份设置
config:
  - backup_root: backup
containers:
  # PostgreSQL卷备份配置
  # type: volume 表示这是一个命名卷
  # source: 卷名称，对应Docker中PostgreSQL的数据存储位置，请注意如果使用的是Docker Copmpose，请确保该卷名称与容器实际volume名称一致
  # backup_file: 备份文件名
  # output_dir: 输出目录，用于存放备份文件
  - name: pg-volume
    type: volume
    source: backup-and-restore_pgdata
    backup_file: pg-volume.tar.gz
    output_dir: /volumes

  # PostgreSQL绑定挂载备份配置
  # type: bind 表示这是一个绑定挂载
  # source: 主机上的源数据目录
  # backup_file: 备份文件名
  # output_dir: 输出目录，用于存放备份文件
  # restore_target: 恢复目标目录，可选字段
  - name: pg-bind
    type: bind
    source: bind-mount/data
    # restore_target: /opt/data/restore-pg  # ✅ 可选字段
    backup_file: pg-bind.tar.gz
    output_dir: /binds
```

### 字段说明

| 字段名        | 说明                                   |
|---------------|----------------------------------------|
| `name`        | 容器标识（仅用于显示，无功能依赖）      |
| `type`        | 数据类型，支持 `volume` 或 `bind`       |
| `source`      | 卷名或宿主机挂载目录路径                |
| `backup_file` | 生成的备份文件名                        |
| `output_dir`  | 备份文件输出的目录（相对路径）          |
| `restore_target` | 恢复目标目录，可选字段 |

## 🎥 视频地址

[Docker 容器的备份与恢复](https://www.bilibili.com/video/BV1VqKwztE1A/)

---

> 本项目遵循 Apache 2.0 协议，欢迎引用与修改。
