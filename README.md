# diff_xtrabackup_docker
xtrabackup差异备份docker版，代替宝塔差异数据库备份

## 前置条件
- 机器有Docker
- 机器配置建议2核心2G内存以上
- 安装宝塔（可选）

## 注意
- 当前只对MySQL 5.7进行了测试
- 当前脚本里面的一些变量为宝塔的默认设置，如果不使用宝塔自行修改变量里面的路径

## 使用

```
# 1 配置信息：
# 1.1 数据库用户密码：修改脚本中 MYSQL_USER 和 MYSQL_PASSWORD 变量为实际的数据库用户和密码。
# 1.2 备份目录：修改脚本中 BACKUP_DIR 变量为实际的备份目录。
# 1.3 全量备份间隔天数：修改脚本中 FULL_BACKUP_INTERVAL 变量为实际的全量备份间隔天数。
# 1.4 Xtrabackup 镜像：修改脚本中 XTRABACKUP_IMAGE 变量为实际的 Xtrabackup 镜像。
# 1.5 MySQL 数据目录：修改脚本中 MYSQL_DATA_DIR 变量为实际的 MySQL 数据目录。

# 2 备份脚本执行：
# 2.1 全量备份：脚本会自动执行全量备份，并记录备份日期到 $LAST_FULL_BACKUP_FILE 文件。
# 2.2 增量备份：脚本会自动执行增量备份，备份日期为脚本执行时刻。
# 2.3 准备备份数据：脚本会自动准备备份数据，包括全量备份和多份增量备份。
# 2.4 恢复备份：脚本会自动恢复备份，恢复时会停止 MySQL 服务，清空 MySQL 数据目录，并恢复备份数据。

# 3 备份脚本定时执行：
# 3.1 使用 crontab 定时任务调度脚本：
# 3.1.1 编辑 crontab：crontab -e
# 3.1.2 添加定时任务：添加以下内容，每天凌晨 2 点执行备份脚本：
# 0 2 * * * /path/to/backup_script.sh
# 3.1.3 保存并退出：保存并退出。
# 3.1.4 验证定时任务：运行 crontab -l 命令，查看定时任务是否添加成功。
#----------------------------------------------------------
# 1 给脚本添加执行权限：
# chmod +x /path/to/backup_script.sh

# 2 使用 cron 定时任务调度脚本：
# crontab -e
# 添加以下内容，每天凌晨 2 点执行备份脚本：
# 0 2 * * * /path/to/backup_script.sh

#----------------------------------------------------------

# 示例调用准备备份数据和恢复备份
# 恢复1 准备包含多份增量备份的情况 准备备份数据：调用 prepare_backup 函数，第一个参数为全量备份目录，后续参数依次为要合并的增量备份目录，按备份时间顺序排列。
# prepare_backup "$FULL_BACKUP_DIR/20250502120000" "$INCREMENTAL_BACKUP_DIR/20250503120000" "$INCREMENTAL_BACKUP_DIR/20250504120000"

# 恢复2 恢复备份：调用 restore_backup 函数，参数为准备好的全量备份目录。
# restore_backup "$FULL_BACKUP_DIR/20250502120000"
```

