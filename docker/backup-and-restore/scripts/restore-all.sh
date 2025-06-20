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