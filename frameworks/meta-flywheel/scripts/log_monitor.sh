#!/bin/bash
# Meta Flywheel 日志监控核心脚本

# 配置项
LOG_DIR="/Users/mahaoxuan/.claude/projects/-Users-mahaoxuan/memory/dev_logs"
BUG_KB="/Users/mahaoxuan/.claude/projects/-Users-mahaoxuan/memory/bug_knowledge_base.md"
SKILLS_DIR="/Users/mahaoxuan/.claude/skills"
QUICK_SKILLS_DIR="/Users/mahaoxuan/.claude/skills/quick"

# 初始化目录
mkdir -p $LOG_DIR $QUICK_SKILLS_DIR
touch $BUG_KB

# 任务状态跟踪
CURRENT_TASK=""
TASK_START_TIME=""
TASK_COMMANDS=()
TASK_ERRORS=()
TASK_SOLUTIONS=()

# 监控终端命令历史
monitor_commands() {
    tail -n 0 -f ~/.zsh_history | while read line; do
        # 提取命令内容
        cmd=$(echo "$line" | sed 's/^[^;]*;//')

        # 跳过飞轮自身的命令
        if [[ "$cmd" == *"flywheel"* ]]; then
            continue
        fi

        # 识别任务开始
        if [[ -z "$CURRENT_TASK" ]]; then
            CURRENT_TASK=$(echo "$cmd" | head -c 50)
            TASK_START_TIME=$(date +%Y%m%d-%H%M%S)
            echo "🚀 开始监控新任务：$CURRENT_TASK" >&2
        fi

        # 记录命令
        TASK_COMMANDS+=("$cmd")

        # 执行命令并捕获输出
        output=$(eval "$cmd" 2>&1)
        exit_code=$?

        # 检查是否有错误
        if [[ $exit_code -ne 0 ]]; then
            error_msg=$(echo "$output" | tail -n 10)
            TASK_ERRORS+=("$error_msg")
            echo "❌ 检测到错误：$error_msg" >&2
        fi

        # 检查任务是否完成
        if [[ "$cmd" == *"git commit"* || "$cmd" == *"npm run build"* || "$cmd" == *"deploy"* || "$cmd" == *"done"* ]]; then
            save_task_log
            if [[ $exit_code -eq 0 ]]; then
                encapsulate_skill
            fi
            reset_task
        fi
    done
}

# 保存任务日志
save_task_log() {
    log_file="$LOG_DIR/$(echo $CURRENT_TASK | tr ' ' '_' | tr '/' '_')-$TASK_START_TIME.md"

    cat > "$log_file" << EOF
# 开发日志：$CURRENT_TASK
- 开始时间：$TASK_START_TIME
- 结束时间：$(date +%Y%m%d-%H%M%S)
- 执行状态：$( [ ${#TASK_ERRORS[@]} -eq 0 ] && echo "✅ 成功" || echo "⚠️  有错误" )

## 执行命令
EOF

    for cmd in "${TASK_COMMANDS[@]}"; do
        echo "- \`$cmd\`" >> "$log_file"
    done

    if [[ ${#TASK_ERRORS[@]} -gt 0 ]]; then
        cat >> "$log_file" << EOF

## 遇到的问题
EOF
        for err in "${TASK_ERRORS[@]}"; do
            echo "- $err" >> "$log_file"
            # 同步到bug知识库
            echo "- **$(date +%Y-%m-%d)** $err" >> "$BUG_KB"
        done
    fi

    echo "📝 任务日志已保存：$log_file" >&2
}

# 封装为Skill
encapsulate_skill() {
    # 简单的自动命名
    skill_name=$(echo "$CURRENT_TASK" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 30)
    skill_dir="$SKILLS_DIR/$skill_name"

    mkdir -p "$skill_dir"

    # 生成SKILL.md
    cat > "$skill_dir/SKILL.md" << EOF
---
name: $skill_name
description: 自动封装的Skill，用于完成：$CURRENT_TASK
---
# $skill_name Skill

## 功能说明
自动从成功执行的任务封装而来，用于完成以下操作：
$CURRENT_TASK

## 使用方法
按以下步骤执行：
EOF

    for cmd in "${TASK_COMMANDS[@]}"; do
        echo "- \`$cmd\`" >> "$skill_dir/SKILL.md"
    done

    echo "✅ 已自动封装为新Skill：$skill_name" >&2
    echo "🚀 调用方式：直接说\"使用$skill_name完成任务\"即可使用" >&2
}

# 重置任务状态
reset_task() {
    CURRENT_TASK=""
    TASK_START_TIME=""
    TASK_COMMANDS=()
    TASK_ERRORS=()
    TASK_SOLUTIONS=()
}

# 处理用户命令
case "$1" in
    start)
        echo "Meta Flywheel 已启动，开始监控终端日志..."
        monitor_commands
        ;;
    stop)
        pkill -f "log_monitor.sh start"
        echo "Meta Flywheel 已停止"
        ;;
    status)
        if pgrep -f "log_monitor.sh start" > /dev/null; then
            echo "✅ Meta Flywheel 正在运行"
        else
            echo "❌ Meta Flywheel 未运行"
        fi
        ;;
    *)
        echo "使用方法："
        echo "  ./log_monitor.sh start   启动监控"
        echo "  ./log_monitor.sh stop    停止监控"
        echo "  ./log_monitor.sh status  查看状态"
        ;;
esac
