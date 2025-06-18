#!/bin/bash
# 设置脚本选项，-e 表示遇到错误立即退出
set -e

# 配置文件路径
CONFIG_FILE="./backup/containers.yml"

# 显示配置文件加载信息
echo "📦 Loading configuration from $CONFIG_FILE..."

# 获取容器数量
containers=$(yq e '.containers | length' "$CONFIG_FILE")

# 遍历所有容器进行恢复操作
for i in $(seq 0 $((containers - 1))); do
  # 从配置文件中提取容器相关信息
  name=$(yq e ".containers[$i].name" "$CONFIG_FILE")
  type=$(yq e ".containers[$i].type" "$CONFIG_FILE")
  source=$(yq e ".containers[$i].source" "$CONFIG_FILE")
  backup_file=$(yq e ".containers[$i].backup_file" "$CONFIG_FILE")
  output_dir=$(yq e ".containers[$i].output_dir" "$CONFIG_FILE")

  # 显示正在恢复的容器信息
  echo "♻️ Restoring [$name] from $output_dir/$backup_file (type: $type)"

  # 根据不同的类型执行相应的恢复操作
  if [[ "$type" == "volume" ]]; then
    # 对于volume类型：
    # 1. 删除已存在的volume（如果存在）
    # 2. 创建新的volume
    # 3. 使用alpine镜像将备份文件解压到volume中
    echo "🔁 Recreating volume: $source"
    docker volume rm "$source" || true
    docker volume create "$source"
    docker run --rm -v "$source":/data -v "$(pwd)/$output_dir":/backup alpine \
      tar -xzvf "/backup/$backup_file" -C /data

  elif [[ "$type" == "bind" ]]; then
    # 对于bind类型：
    # 1. 清空目标目录内容
    # 2. 将备份文件解压到目标目录
    echo "🧹 Cleaning bind directory: $source"
    rm -rf "$source"/*
    tar -xzvf "$output_dir/$backup_file" -C "$source"

  else
    # 未知类型时输出错误信息
    echo "❌ Unknown type [$type] for [$name]"
  fi
done