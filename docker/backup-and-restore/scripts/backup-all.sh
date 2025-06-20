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

# 全局配置
# CONFIG_FILE: 配置文件路径，包含容器备份信息
CONFIG_FILE="./containers.yml"
echo "📦 Loading configuration from $CONFIG_FILE..."

# 获取容器数量
containers=$(yq '.containers | length' "$CONFIG_FILE")
echo "📦 Total containers: $containers"

# 遍历所有容器进行备份操作
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

  mkdir -p "$output_dir"

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

  echo "🔄 Backing up [$name] → $output_dir/$backup_file (type: $type)"

  if [[ "$type" == "volume" ]]; then
    docker run --rm \
      -v "$source":/data \
      -v "$(pwd)/$output_dir":/backup \
      alpine \
      tar -czf "/backup/$backup_file" -C /data .
  elif [[ "$type" == "bind" ]]; then
    if [[ -d "$source" ]]; then
      tar -czf "$output_dir/$backup_file" -C "$source" .
    else
      echo "❌ Source directory not found for [$name]: $source"
    fi
  else
    echo "❌ Unknown type [$type] for [$name]"
  fi
done

# 打包 backup 目录为归档
echo "📦 Packaging entire backup folder into all-backup.tar.gz"
tar -czf all-backup.tar.gz -C ./ backup
echo "✅ All backups completed. Archive: all-backup.tar.gz"

# 交互式清理
function cleanup_files {
  read -rp "🧹 Do you want to delete the 'backup' folder now? (y/n): " cleanup
  case "$cleanup" in
    y|Y)
      rm -rf backup
      rm -f all-backup.tar.gz
      echo "✅ Cleanup completed."
      ;;
    n|N)
      echo "🗂️  'backup' folder retained."
      ;;
    *)
      echo "⚠️ Invalid input. Please enter y or n."
      cleanup_files  # 递归调用重试
      ;;
  esac
}

# 调用清理函数
cleanup_files
