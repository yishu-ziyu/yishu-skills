#!/bin/bash
# Meta Flywheel v2.0 核心执行脚本
# 持续运转的自我增强系统

set -e

# ============================================================
# 配置区域
# ============================================================
FLYWHEEL_ROOT="$HOME/.claude/projects/-Users-mahaoxuan/memory/meta-flywheel"
STATE_FILE="$FLYWHEEL_ROOT/state.json"
BUG_INDEX="$FLYWHEEL_ROOT/bug_knowledge/index.json"
BUG_RECORDS="$FLYWHEEL_ROOT/bug_knowledge/records"
SKILLS_DIR="$HOME/.claude/skills"
QUICK_SKILLS_DIR="$HOME/.claude/skills/quick"
LOGS_DIR="$FLYWHEEL_ROOT/logs"
ITERATIONS_DIR="$FLYWHEEL_ROOT/iterations"
PATTERNS_FILE="$FLYWHEEL_ROOT/patterns/patterns.json"

# 初始化目录结构
init_directories() {
    mkdir -p "$BUG_RECORDS" "$LOGS_DIR" "$ITERATIONS_DIR" "$FLYWHEEL_ROOT/patterns"
    mkdir -p "$SKILLS_DIR" "$QUICK_SKILLS_DIR"
    touch "$STATE_FILE" "$BUG_INDEX" "$PATTERNS_FILE"
}

# ============================================================
# 状态管理
# ============================================================
load_state() {
    if [[ -f "$STATE_FILE" ]] && [[ -s "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo '{}'
    fi
}

save_state() {
    local state="$1"
    echo "$state" > "$STATE_FILE"
    # 同时备份
    echo "$state" > "${STATE_FILE}.backup"
}

update_state() {
    local key="$1"
    local value="$2"
    local state=$(load_state)
    # 使用 jq 更新（如果可用）或手动解析
    if command -v jq &> /dev/null; then
        echo "$state" | jq --arg "$key" "$value" '. + {($key): $value}' > "${STATE_FILE}.tmp"
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
}

# ============================================================
# Bug 知识库
# ============================================================
generate_fingerprint() {
    local error_msg="$1"
    # 简化的指纹生成：取错误类型的哈希
    echo "$error_msg" | sha256sum | cut -c1-16
}

log_bug() {
    local error_msg="$1"
    local context="$2"
    local solution="$3"
    local task_id="${4:-unknown}"
    
    init_directories
    
    local fingerprint=$(generate_fingerprint "$error_msg")
    local bug_id="bug-$(date +%Y%m%d-%H%M%S)-$RANDOM"
    
    # 构建 Bug 记录
    local record=$(cat << EOF
{
  "id": "$bug_id",
  "fingerprint": "$fingerprint",
  "error_message": "$(echo "$error_msg" | jq -Rs .)",
  "context": {
    "task": "$task_id",
    "recorded_at": "$(date -Iseconds)"
  },
  "investigation": {
    "attempts": [],
    "recorded": true
  },
  "solution": {
    "fix": "$(echo "$solution" | jq -Rs .)",
    "verified": false
  },
  "quality": {
    "resolution_time": 0,
    "occurrence_count": 1,
    "helped_count": 0
  },
  "meta": {
    "created_at": "$(date -Iseconds)",
    "updated_at": "$(date -Iseconds)"
  }
}
EOF
)
    
    # 保存记录
    echo "$record" | jq . > "$BUG_RECORDS/${bug_id}.json"
    
    # 更新索引
    if [[ -f "$BUG_INDEX" ]] && [[ -s "$BUG_INDEX" ]]; then
        local index=$(cat "$BUG_INDEX")
        echo "$index" | jq --argjson record "$record" '.bugs += [$record] | .by_fingerprint[$fingerprint] = $record' > "${BUG_INDEX}.tmp"
        mv "${BUG_INDEX}.tmp" "$BUG_INDEX"
    else
        echo '{"bugs": [], "by_fingerprint": {}}' | jq --argjson record "$record" '.bugs += [$record] | .by_fingerprint[$fingerprint] = $record' > "$BUG_INDEX"
    fi
    
    echo "🧠 Bug 已记录: $bug_id"
    echo "$bug_id"
}

search_bug() {
    local error_msg="$1"
    local fingerprint=$(generate_fingerprint "$error_msg")
    
    if [[ ! -f "$BUG_INDEX" ]]; then
        return 1
    fi
    
    # 精确匹配
    local match=$(cat "$BUG_INDEX" | jq --arg fp "$fingerprint" '.by_fingerprint[$fp]')
    if [[ "$match" != "null" ]]; then
        echo "$match"
        return 0
    fi
    
    # 模糊匹配 - 搜索相似错误类型
    local error_type=$(echo "$error_msg" | grep -oE '(Error|Exception|Warning):\s*\K[^ ]+' | head -1 || echo "")
    if [[ -n "$error_type" ]]; then
        match=$(cat "$BUG_INDEX" | jq --arg type "$error_type" '[.bugs[] | select(.error_message | contains($type))] | first')
        if [[ "$match" != "null" ]]; then
            echo "$match"
            return 0
        fi
    fi
    
    return 1
}

# ============================================================
# 高频模式检测
# ============================================================
PATTERN_COUNTER_FILE="$FLYWHEEL_ROOT/patterns/counter.json"

track_pattern() {
    local pattern="$1"
    local command="$2"
    
    mkdir -p "$FLYWHEEL_ROOT/patterns"
    touch "$PATTERN_COUNTER_FILE"
    
    local patterns=$(cat "$PATTERN_COUNTER_FILE")
    
    # 检查模式是否存在
    local existing=$(echo "$patterns" | jq --arg p "$pattern" '.patterns[$p]')
    
    if [[ "$existing" == "null" ]]; then
        # 新增模式
        echo "$patterns" | jq --arg p "$pattern" --arg cmd "$command" \
            '.patterns[$p] = {"count": 1, "first_seen": "'$(date -Iseconds)'", "commands": [$cmd]}' > "${PATTERN_COUNTER_FILE}.tmp"
    else
        # 更新计数
        local count=$(echo "$existing" | jq '.count')
        local commands=$(echo "$existing" | jq '.commands + [$cmd]')
        echo "$patterns" | jq --arg p "$pattern" --argjson count $((count + 1)) --argjson commands "$commands" \
            '.patterns[$p].count = $count | .patterns[$p].commands = $commands' > "${PATTERN_COUNTER_FILE}.tmp"
    fi
    
    mv "${PATTERN_COUNTER_FILE}.tmp" "$PATTERN_COUNTER_FILE"
    
    # 检查是否达到阈值（3次）
    local new_count=$(echo "$patterns" | jq --arg p "$pattern" '.patterns[$p].count')
    if [[ $new_count -ge 3 ]]; then
        echo "⚡ 检测到高频模式: $pattern (出现 $new_count 次)"
        echo "💡 建议封装为快速 Skill"
    fi
}

# ============================================================
# Skill 封装
# ============================================================
encapsulate_skill() {
    local task_name="$1"
    local steps="$2"
    local skill_type="${3:-full}"  # full | quick
    
    local skill_dir
    local skill_name_slug=$(echo "$task_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | head -c 30)
    
    if [[ "$skill_type" == "quick" ]]; then
        skill_dir="$QUICK_SKILLS_DIR/$skill_name_slug"
    else
        skill_dir="$SKILLS_DIR/$skill_name_slug"
    fi
    
    mkdir -p "$skill_dir"
    
    # 生成 Skill 文件
    cat > "$skill_dir/SKILL.md" << EOF
---
name: $skill_name_slug
description: 自动从任务 [$task_name] 封装的 Skill | $(date +%Y-%m-%d)
compatibility:
  - Requires Bash tool
  - Requires File system tools
---

# $task_name Skill

## 功能说明
自动从成功执行的任务封装而来。

## 使用步骤
$steps

## 触发词
- 帮我$task_name
- 使用$task_name

## 执行命令
\`\`\`bash
$steps
\`\`\`

---
*由 Meta Flywheel v2.0 自动生成 | $(date -Iseconds)*
EOF
    
    # 更新统计
    local state=$(load_state)
    local skills_count=$(echo "$state" | jq '.stats.skills_encapsulated //= 0; .stats.skills_encapsulated + 1')
    echo "$state" | jq ".stats.skills_encapsulated = $skills_count" > "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    echo "✅ 已封装 Skill: $skill_name_slug"
    echo "📁 位置: $skill_dir"
}

# ============================================================
# 自迭代
# ============================================================
iterate_flywheel() {
    init_directories
    
    local iteration_num=$(date +%Y%m%d-%H%M%S)
    local iter_file="$ITERATIONS_DIR/iter-$iteration_num.md"
    
    # 收集分析数据
    local analysis=$(cat << EOF
# Meta Flywheel 迭代 #$iteration_num

## 时间
$(date -Iseconds)

## 统计
- Skills 总数: $(find "$SKILLS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
- 快速 Skills: $(find "$QUICK_SKILLS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
- Bug 记录: $(cat "$BUG_INDEX" 2>/dev/null | jq '.bugs | length' || echo 0)

## 高频模式
$(cat "$PATTERN_COUNTER_FILE" 2>/dev/null | jq -r '.patterns | to_entries[] | "\(.key): \(.value.count) 次"')

## 待优化项
$(jq -r '.patterns | to_entries[] | select(.value.count >= 3) | "- 高频模式: \(.key) (\(.value.count) 次)"' "$PATTERN_COUNTER_FILE" 2>/dev/null || echo "无")

## 行动项
EOF
)
    
    echo "$analysis" > "$iter_file"
    
    # 检查高频模式并建议封装
    if [[ -f "$PATTERN_COUNTER_FILE" ]]; then
        jq -r '.patterns | to_entries[] | select(.value.count >= 3) | "- 封装: \(.key)"' "$PATTERN_COUNTER_FILE" >> "$iter_file"
    fi
    
    # 更新迭代计数
    local state=$(load_state)
    echo "$state" | jq ".iteration_count = (.iteration_count // 0 + 1) | .last_iteration = \"$(date -Iseconds)\"" > "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    echo "🔧 迭代完成: $iteration_num"
}

# ============================================================
# 飞轮主循环
# ============================================================
start_flywheel() {
    echo "🔄 Meta Flywheel v2.0 启动中..."
    
    init_directories
    
    # 初始化状态
    if [[ ! -f "$STATE_FILE" ]] || [[ ! -s "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" << EOF
{
  "version": "2.0.0",
  "status": "running",
  "started_at": "$(date -Iseconds)",
  "iteration_count": 0,
  "current_task": null,
  "stats": {
    "tasks_completed": 0,
    "skills_encapsulated": 0,
    "bugs_logged": 0,
    "time_saved_minutes": 0
  }
}
EOF
    else
        # 更新状态为运行中
        local state=$(load_state)
        echo "$state" | jq '.status = "running" | .started_at = "'$(date -Iseconds)'"' > "${STATE_FILE}.tmp"
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
    
    echo "✅ Meta Flywheel 已启动"
    echo "📊 状态: $(cat "$STATE_FILE" | jq '.status')"
    echo "💡 使用 /flywheel status 查看详细状态"
}

stop_flywheel() {
    local state=$(load_state)
    echo "$state" | jq '.status = "stopped"' > "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    echo "⏹️  Meta Flywheel 已停止"
}

show_status() {
    local state=$(load_state)
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Meta Flywheel v2.0 状态"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "版本: $(echo "$state" | jq -r '.version')"
    echo "状态: $(echo "$state" | jq -r '.status')"
    echo "启动: $(echo "$state" | jq -r '.started_at')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 统计"
    echo "  - 完成任务: $(echo "$state" | jq '.stats.tasks_completed')"
    echo "  - 封装 Skills: $(echo "$state" | jq '.stats.skills_encapsulated')"
    echo "  - 记录 Bugs: $(echo "$state" | jq '.stats.bugs_logged')"
    echo "  - 节省时间: $(echo "$state" | jq '.stats.time_saved_minutes') 分钟"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 迭代"
    echo "  - 迭代次数: $(echo "$state" | jq '.iteration_count')"
    echo "  - 上次迭代: $(echo "$state" | jq -r '.last_iteration // "从未"')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

show_logs() {
    local date="${1:-$(date +%Y-%m-%d)}"
    local log_file="$LOGS_DIR/flywheel-$date.log"
    
    if [[ -f "$log_file" ]]; then
        tail -50 "$log_file"
    else
        echo "📋 暂无日志: $log_file"
        echo "💡 日志将在后台运行时生成"
    fi
}

# ============================================================
# 命令路由
# ============================================================
case "$1" in
    start)
        start_flywheel
        ;;
    stop)
        stop_flywheel
        ;;
    status)
        show_status
        ;;
    log)
        show_logs "$2"
        ;;
    iterate|evolve)
        iterate_flywheel
        ;;
    log-bug)
        log_bug "$2" "$3" "$4" "$5"
        ;;
    search-bug)
        search_bug "$2"
        ;;
    track)
        track_pattern "$2" "$3"
        ;;
    encapsulate)
        encapsulate_skill "$2" "$3" "$4"
        ;;
    *)
        cat << EOF
Meta Flywheel v2.0
用法: flywheel <命令>

命令:
  start           启动飞轮
  stop            停止飞轮
  status          查看状态
  log [日期]      查看日志 (默认今天)
  iterate         手动触发迭代
  log-bug <错误> [上下文] [解决方案] [任务ID]
  search-bug <错误>  搜索已知 Bug
  track <模式> <命令>  追踪高频操作
  encapsulate <名称> <步骤> [类型]

示例:
  flywheel start
  flywheel status
  flywheel log-bug "TypeError: Cannot read property" "读取 user.json" "检查文件存在" "task-123"
  flywheel search-bug "TypeError"
  flywheel track "git commit" "git commit -m 'fix: ...'"
EOF
        ;;
esac
