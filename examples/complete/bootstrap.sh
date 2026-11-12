#!/usr/bin/env bash
set -euo pipefail

# 为自定义批处理程序准备节点本地的共享临时目录。
# 此脚本在应用安装前执行，只使用系统命令，不依赖 Hadoop 或 Spark。
# 1777 允许作业用户写入，并限制用户删除其他用户的文件。
install -d -m 1777 /var/tmp/emr-batch
printf '批处理临时目录已准备：/var/tmp/emr-batch\n'
