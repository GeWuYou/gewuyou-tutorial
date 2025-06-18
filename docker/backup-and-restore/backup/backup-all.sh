#!/bin/bash
set -e

# CONFIG_FILE: 配置文件路径，包含容器备份配置信息
CONFIG_FILE="./backup/containers.yml"

# 输出初始提示信息，显示正在加载的配置文件路径
echo "📦 Loading configuration from $CONFIG_FILE..."

# containers: 获取配置文件中定义的容器数量
containers=$(yq e '.containers | length' "$CONFIG_FILE")

# 遍历所有容器配置项
for i in $(seq 0 $((containers - 1))); do
  # name: 当前容器的名称
  name=$(yq e ".containers[$i].name" "$CONFIG_FILE")
  # type: 当前容器的类型（volume/bind）
  type=$(yq e ".containers[$i].type" "$CONFIG_FILE")
  # source: 数据源路径（volume挂载点或bind路径）
  source=$(yq e ".containers[$i].source" "$CONFIG_FILE")
  # backup_file: 备份生成的tar.gz文件名
  backup_file=$(yq e ".containers[$i].backup_file" "$CONFIG_FILE")
  # output_dir: 备份文件输出目录
  output_dir=$(yq e ".containers[$i].output_dir" "$CONFIG_FILE")

  # 创建输出目录（如果不存在）
  mkdir -p "$output_dir"
  # 显示当前正在备份的容器信息
  echo "🔄 Backing up [$name] → $output_dir/$backup_file (type: $type)"

  # 根据容器类型执行相应的备份操作
  if [[ "$type" == "volume" ]]; then
    # volume类型：使用docker容器挂载卷进行打包
    docker run --rm -v "$source":/data -v "$(pwd)/$output_dir":/backup alpine \
      tar -czvf "/backup/$backup_file" -C /data .
  elif [[ "$type" == "bind" ]]; then
    # bind类型：直接对本地目录进行打包
    tar -czvf "$output_dir/$backup_file" -C "$source" .
  else
    # 不支持的类型时输出错误信息
    echo "❌ Unknown type [$type] for [$name]"
  fi
done