#!/bin/bash
# 只在MySQL 5.7 版本测试过
# 配置信息
MYSQL_USER="root"       # 数据库用户 建议使用 root 用户
MYSQL_PASSWORD="yourpassword"  # 数据库密码
BACKUP_DIR="/backup"  # 备份目录
FULL_BACKUP_DIR="$BACKUP_DIR/full_backup"  # 全量备份目录
INCREMENTAL_BACKUP_DIR="$BACKUP_DIR/incremental_backup"  # 增量备份目录
LAST_FULL_BACKUP_FILE="$BACKUP_DIR/last_full_backup"  # 上次全量备份文件
FULL_BACKUP_INTERVAL=7  # 全量备份间隔天数
XTRABACKUP_IMAGE="percona/percona-xtrabackup:2.4"  # Xtrabackup 镜像 2.4 版本 对应 MySQL 5.7
MYSQL_DATA_DIR="/www/server/data"  # MySQL 数据目录
MYSQL_BASE_DIR="/www/server/mysql"  # MySQL 基础目录
MYSQL_CONFIG_FILE="/etc/my.cnf"  # MySQL 配置文件
MYSQL_PORT="3306"  # MySQL 端口
MYSQL_SOCKET="/tmp/mysql.sock"  # MySQL 套接字

# 执行备份的通用函数
run_backup() {
    local target_dir="$1"
    local incremental_basedir="$2"

    #local cmd="docker run --rm --privileged --network=host \ # 如果要在宝塔的计划任务里面运行，需要使用本行
    local cmd="docker run --rm -it --privileged --network=host \
        -v \"$BACKUP_DIR\":\"$BACKUP_DIR\" \
        -v \"$MYSQL_CONFIG_FILE\":/etc/my.cnf:ro \
        -v \"$MYSQL_SOCKET\":\"$MYSQL_SOCKET\":ro \
        -v \"$MYSQL_BASE_DIR\":\"$MYSQL_BASE_DIR\":ro \
        -v \"$MYSQL_DATA_DIR\":\"$MYSQL_DATA_DIR\":rw \
        \"$XTRABACKUP_IMAGE\" \
        xtrabackup --backup \
        --host=localhost \
        --user=\"$MYSQL_USER\" \
        --password=\"$MYSQL_PASSWORD\" \
        --port=\"$MYSQL_PORT\" \
        --socket=\"$MYSQL_SOCKET\" \
        --target-dir=\"$target_dir\""

    if [ -n "$incremental_basedir" ]; then
        cmd="$cmd --incremental-basedir=\"$incremental_basedir\""
    fi

    echo "执行命令: $cmd"
    eval $cmd

    return $?
}

# 全量备份函数
full_backup() {
    local backup_date=$(date +%Y%m%d%H%M%S)
    local target_dir="$FULL_BACKUP_DIR/$backup_date"

    if run_backup "$target_dir" ""; then
        echo "$backup_date" > "$LAST_FULL_BACKUP_FILE"
        echo "全量备份成功，备份目录: $target_dir"
    else
        echo "全量备份失败"
        exit 1
    fi
}

# 增量备份函数
incremental_backup() {
    if [ ! -f "$LAST_FULL_BACKUP_FILE" ]; then
        echo "未找到全量备份记录，请先进行全量备份。"
        exit 1
    fi

    local last_full_backup=$(cat "$LAST_FULL_BACKUP_FILE")
    local last_full_dir="$FULL_BACKUP_DIR/$last_full_backup"
    local backup_date=$(date +%Y%m%d%H%M%S)
    local target_dir="$INCREMENTAL_BACKUP_DIR/$backup_date"

    if run_backup "$target_dir" "$last_full_dir"; then
        echo "增量备份成功，备份目录: $target_dir"
    else
        echo "增量备份失败"
        exit 1
    fi
}

# 判断是否需要全量备份
if [ ! -f "$LAST_FULL_BACKUP_FILE" ]; then
    full_backup
else
    last_full_backup_date=$(cat "$LAST_FULL_BACKUP_FILE")
    # 将日期字符串转换为 YYYY-MM-DD HH:MM:SS 格式
    formatted_date=$(echo "$last_full_backup_date" | sed 's/\(....\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1-\2-\3 \4:\5:\6/')
    # 获取当前时间戳
    current_timestamp=$(date +%s)
    # 获取上次全量备份的时间戳
    last_full_timestamp=$(date -d "$formatted_date" +%s)
    if [ $? -eq 0 ]; then
        days_since_last_full=$(( (current_timestamp - last_full_timestamp) / 86400 ))
        if [ $days_since_last_full -ge $FULL_BACKUP_INTERVAL ]; then
            full_backup
        else
            incremental_backup
        fi
    else
        echo "日期解析失败，执行全量备份"
        full_backup
    fi
fi
