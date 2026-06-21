---
name: meta-flywheel
description: 元认知飞轮 Skill v2.0 - 持续运转的自我增强系统。自动监控终端/IDE/文件系统，智能识别任务流，沉淀经验到可复用 Skills，构建个人 Bug 知识库，具备自迭代能力。
compatibility:
  - Requires Bash tool for system monitoring
  - Requires Write/Edit tools for log recording and Skill creation
  - Requires Task tracking tools for process monitoring
  - Requires File system tools for state persistence
  - Runs as background daemon when activated
---

# Meta Flywheel v2.0 元认知飞轮

> **像重力一样持续运转的自我增强系统**

## 核心理念

```
┌──────────────────────────────────────────────────────────────────┐
│                        META FLYWHEEL v2.0                       │
│                                                                  │
│   感知层 ──→ 决策层 ──→ 执行层 ──→ 沉淀层 ──→ 进化层           │
│     ↑                                                        ↓   │
│     └────────────────────── 反馈循环 ←────────────────────────┘   │
│                                                                  │
│   执行任务 → 记录过程 → 解决 Bug → 沉淀经验 → 封装 Skill          │
│       ↑                                              ↓            │
│       └── 优化飞轮 ← 复用提升效率 ← 迭代升级 ←──┘            │
└──────────────────────────────────────────────────────────────────┘
```

## 感知层 (Perception)

### 多源事件监听

```typescript
// 感知层支持的事件源
interface PerceptionSources {
  // 1. Shell 命令历史 (已有)
  shell: {
    enabled: true,
    history_file: "~/.zsh_history",
    filters: ["flywheel", "password", "secret"]
  };
  
  // 2. OpenCode Session 事件 (新增)
  opencode: {
    enabled: true,
    events: [
      "task_created",      // 新任务创建
      "task_completed",     // 任务完成
      "task_failed",        // 任务失败
      "agent_started",      // Agent 启动
      "agent_finished",      // Agent 完成
      "todo_updated",       // Todo 状态变更
      "file_created",       // 文件创建
      "file_modified",      // 文件修改
      "command_executed",   // 命令执行
      "error_occurred"      // 错误发生
    ]
  };
  
  // 3. 文件系统事件 (新增)
  filesystem: {
    enabled: true,
    watch_paths: [
      "~/.claude/projects",      // 项目目录
      "~/.claude/skills",        // Skills 目录
      "~/.claude/memory"          // 记忆库
    ],
    events: ["create", "modify", "delete"]
  };
  
  // 4. Git 事件 (新增)
  git: {
    enabled: true,
    events: ["commit", "push", "branch", "merge", "conflict"]
  }
}
```

### 智能任务识别

```typescript
// 任务识别引擎
class TaskRecognizer {
  // 从用户意图识别任务开始
  detect_task_start(context: Context): TaskStart | null {
    // 触发模式
    const startPatterns = [
      "帮我", "我要", "我想", "需要", "做一下",
      "implement", "create", "add", "fix", "build",
      "写一个", "开发", "重构", "优化"
    ];
    
    // 排除模式（闲聊）
    const excludePatterns = [
      "你觉得", "什么是", "解释", "怎么样",
      "what is", "how does", "explain", "tell me"
    ];
    
    // 检测逻辑
    if (matches_any(context.input, startPatterns) && 
        !matches_any(context.input, excludePatterns)) {
      return {
        id: generate_uuid(),
        name: extract_task_name(context.input),
        type: classify_task_type(context.input),
        priority: estimate_priority(context.input),
        start_time: now(),
        source: context.source  // "user_message" | "shell" | "file"
      };
    }
    return null;
  }
  
  // 任务类型分类
  classify_task_type(input: string): TaskType {
    if (matches_any(input, ["bug", "修复", "error", "fix"])) return "bug_fix";
    if (matches_any(input, ["添加", "新增", "implement", "add"])) return "feature";
    if (matches_any(input, ["重构", "refactor", "优化"])) return "refactor";
    if (matches_any(input, ["测试", "test"])) return "test";
    if (matches_any(input, ["部署", "deploy"])) return "deploy";
    return "general";
  }
}
```

## 决策层 (Decision)

### 自动决策引擎

```typescript
// 决策规则引擎
class FlywheelDecider {
  // 基于事件类型决定行动
  decide(event: FlywheelEvent): Action[] {
    const actions: Action[] = [];
    
    switch (event.type) {
      case "task_completed":
        // 检查是否需要封装 Skill
        if (this.should_encapsulate(event.task)) {
          actions.push({ type: "encapsulate_skill", task: event.task });
        }
        // 检查是否需要更新知识库
        if (event.task.has_bugs) {
          actions.push({ type: "update_knowledge_base", task: event.task });
        }
        break;
        
      case "error_occurred":
        // 提取错误信息并记录
        actions.push({ type: "log_error", error: event.error });
        actions.push({ type: "search_solution", error: event.error });
        break;
        
      case "repeated_pattern":
        // 高频操作检测
        actions.push({ type: "suggest_quick_skill", pattern: event.pattern });
        break;
        
      case "task_failed":
        // 分析失败原因
        actions.push({ type: "analyze_failure", task: event.task });
        break;
    }
    
    return actions;
  }
  
  // 判断是否应该封装为 Skill
  should_encapsulate(task: Task): boolean {
    return (
      task.complexity >= 7 &&           // 复杂度 >= 7
      task.step_count >= 3 &&            // 至少 3 步
      task.success_rate >= 0.8 &&       // 成功率 >= 80%
      !this.already_encapsulated(task)  // 尚未封装
    );
  }
}
```

## 执行层 (Execution)

### Skill 封装引擎

```typescript
// 完整的 Skill 封装模板
function generate_skill_package(task: Task): SkillPackage {
  return {
    metadata: {
      name: generate_skill_name(task),
      display_name: task.name.zh,
      description: summarize_task(task),
      version: "1.0.0",
      author: "meta-flywheel",
      created_at: now(),
      tags: extract_tags(task),
      triggers: generate_triggers(task),
      category: classify_category(task)
    },
    
    compatibility: {
      requires: detect_required_tools(task),
      tools: detect_used_tools(task),
      skills: detect_needed_skills(task),
      environment: detect_env(task)
    },
    
    content: {
      overview: generate_overview(task),
      steps: generate_steps(task),
      examples: generate_examples(task),
      error_handling: generate_error_handling(task),
      caveats: extract_caveats(task)
    },
    
    quality: {
      confidence: calculate_confidence(task),
      tested: task.success_count >= 3,
      edge_cases: extract_edge_cases(task)
    }
  };
}

// 生成触发词
function generate_triggers(task: Task): string[] {
  const triggers = [];
  
  // 从任务描述提取
  triggers.push(task.name.en);
  triggers.push(task.name.zh);
  
  // 从步骤提取动作词
  const action_words = extract_action_words(task.steps);
  for (const word of action_words) {
    triggers.push(`帮我${word}`);
    triggers.push(`使用 ${task.name.en} ${word}`);
  }
  
  // 同义词扩展
  triggers.push(...expand_synonyms(triggers));
  
  return deduplicate(triggers);
}
```

## 沉淀层 (沉淀)

### Bug 知识库结构

```typescript
// 结构化 Bug 记录
interface BugRecord {
  id: string;
  fingerprint: string;      // 错误指纹（用于匹配）
  
  // 基本信息
  error_message: string;
  error_type: string;
  stack_trace?: string;
  
  // 上下文
  context: {
    task?: string;
    file?: string;
    command?: string;
    language?: string;
    framework?: string;
  };
  
  // 排查过程
  investigation: {
    attempts: Attempt[];
    root_cause?: string;
    duration?: number;  // 排查耗时(分钟)
  };
  
  // 解决方案
  solution: {
    fix: string;
    code_changes?: CodeChange[];
    workaround?: string;
    verified: boolean;
  };
  
  // 关联
  related: {
    skills?: string[];
    docs?: string[];
    similar_bugs?: string[];
  };
  
  // 质量指标
  quality: {
    resolution_time: number;
    occurrence_count: number;
    helped_count: number;  // 后续遇到时有多少次被直接解决
  };
  
  // 元数据
  meta: {
    created_at: string;
    updated_at: string;
    source_task?: string;
  };
}

// 错误指纹生成
function generate_fingerprint(error: Error): string {
  // 提取错误类型的哈希
  const type_hash = hash(error.name + error.type);
  
  // 提取关键错误信息（去除随机变量）
  const key_info = extract_key_patterns(error.message);
  
  // 提取堆栈中的关键文件和行号
  const stack_key = extract_stack_signature(error.stack);
  
  return hash(type_hash + key_info + stack_key);
}
```

### 快速检索

```typescript
// Bug 检索接口
async function search_bug_knowledge(error: Error): Promise<BugRecord | null> {
  const fingerprint = generate_fingerprint(error);
  
  // 1. 精确匹配
  let record = await db.bugs.findOne({ fingerprint });
  if (record) return record;
  
  // 2. 模糊匹配（相似错误类型）
  record = await db.bugs.findOne({
    error_type: error.type,
    "context.language": detect_language(error)
  });
  if (record) return record;
  
  // 3. 关键词匹配
  const keywords = extract_keywords(error.message);
  record = await db.bugs.findOne({
    $text: { $search: keywords.join(" ") }
  });
  
  return record;
}
```

## 进化层 (Evolution)

### 自迭代机制

```typescript
// 飞轮进化引擎
class FlywheelEvolver {
  private iteration_count = 0;
  private quality_scores: QualityScore[] = [];
  
  // 每 N 个任务迭代一次
  private readonly ITERATION_INTERVAL = 10;
  
  // 收集质量反馈
  async collect_feedback(skill: Skill, result: SkillResult) {
    this.quality_scores.push({
      skill_name: skill.name,
      execution_time: result.duration,
      success: result.success,
      user_satisfaction: result.rating,
      was_used: result.times_used
    });
  }
  
  // 执行迭代
  async iterate() {
    this.iteration_count++;
    
    // 1. 分析 Skill 质量
    const skill_analysis = this.analyze_skills();
    
    // 2. 识别问题模式
    const problems = this.identify_problems(skill_analysis);
    
    // 3. 生成改进建议
    const improvements = this.generate_improvements(problems);
    
    // 4. 应用改进
    for (const improvement of improvements) {
      await this.apply_improvement(improvement);
    }
    
    // 5. 记录迭代
    await this.log_iteration({
      iteration: this.iteration_count,
      problems,
      improvements,
      timestamp: now()
    });
    
    // 6. 备份当前版本
    await this.backup_version();
  }
  
  // 分析 Skill 质量
  private analyze_skills(): SkillAnalysis {
    const scores = this.quality_scores;
    
    return {
      most_used: this.top(scores, "was_used"),
      fastest: this.top(scores, "execution_time"),
      most_successful: this.top_filtered(scores, "success", true),
      lowest_satisfaction: this.bottom(scores, "user_satisfaction"),
      unused: this.find_unused(scores)
    };
  }
  
  // 生成改进建议
  private generate_improvements(problems: Problem[]): Improvement[] {
    const improvements: Improvement[] = [];
    
    for (const problem of problems) {
      switch (problem.type) {
        case "unused_skill":
          improvements.push({
            action: "deprecate",
            target: problem.skill,
            reason: "从未被使用"
          });
          break;
          
        case "low_satisfaction":
          improvements.push({
            action: "refine",
            target: problem.skill,
            changes: this.suggest_refinements(problem)
          });
          break;
          
        case "slow_execution":
          improvements.push({
            action: "optimize",
            target: problem.skill,
            suggestions: this.suggest_optimizations(problem)
          });
          break;
          
        case "high_failure_rate":
          improvements.push({
            action: "add_error_handling",
            target: problem.skill,
            error_patterns: problem.failure_patterns
          });
          break;
      }
    }
    
    return improvements;
  }
}
```

## 持久化层 (Persistence)

### 状态管理

```typescript
// 飞轮状态持久化
interface FlywheelState {
  // 版本控制
  version: string;
  last_iteration: string;
  iteration_count: number;
  
  // 运行时状态
  status: "running" | "paused" | "stopped";
  started_at: string;
  
  // 当前任务
  current_task?: ActiveTask;
  
  // 统计
  stats: {
    tasks_completed: number;
    skills_encapsulated: number;
    bugs_logged: number;
    time_saved_minutes: number;
  };
  
  // 配置
  config: FlywheelConfig;
}

// 状态文件位置
const STATE_FILE = "~/.claude/projects/-Users-mahaoxuan/memory/meta-flywheel/state.json";

// 自动保存
function save_state(state: FlywheelState) {
  write_json(STATE_FILE, state);
  // 同时备份
  write_json(`${STATE_FILE}.backup`, state);
}

// 崩溃恢复
function restore_state(): FlywheelState | null {
  try {
    return read_json(STATE_FILE);
  } catch {
    // 尝试备份
    return read_json(`${STATE_FILE}.backup`);
  }
}
```

## 输出格式

### 用户可见输出

```markdown
# 飞轮通知格式

## Skill 封装完成
```
✅ 已封装新 Skill：[名称]
📌 功能：[一句话描述]
🏷️ 触发词：[list]
🚀 调用：直接说"[触发词]"即可
```

## Bug 已记录
```
🧠 已记录 Bug 到知识库
🔍 错误：[指纹摘要]
💡 方案：[解决方案]
⏱️ 排查耗时：[X] 分钟
```

## 飞轮状态
```
🔄 Meta Flywheel v2.0 运行中
📊 今日：完成 [X] 任务，封装 [Y] Skill
⏰ 运行时间：[Z] 小时
```

## 进化完成
```
🔧 飞轮已迭代 #[N]
📈 优化：[X] 个 Skill
🗑️ 废弃：[Y] 个未使用 Skill
💾 已备份版本：[version]
```
```

## 配置命令

| 命令 | 功能 |
|------|------|
| `/flywheel start` | 启动飞轮（后台运行） |
| `/flywheel stop` | 停止飞轮 |
| `/flywheel status` | 查看运行状态 |
| `/flywheel config` | 配置飞轮参数 |
| `/flywheel stats` | 查看统计信息 |
| `/flywheel logs` | 查看飞轮日志 |
| `/flywheel evolve` | 手动触发迭代 |
| `/flywheel export` | 导出知识库 |

## 文件结构

```
~/.claude/projects/-Users-mahaoxuan/memory/meta-flywheel/
├── state.json                    # 当前状态
├── state.backup.json             # 备份状态
├── iterations/                   # 迭代历史
│   └── iter-001.md
├── skills/                       # 封装的 Skills
│   └── [skill-name]/
│       └── SKILL.md
├── quick/                        # 快速 Skills
│   └── [skill-name]/
│       └── SKILL.md
├── bug_knowledge/               # Bug 知识库
│   ├── index.json                # 索引
│   └── records/                  # 详细记录
│       └── [bug-id].json
├── patterns/                     # 高频模式
│   └── patterns.json
└── logs/                         # 飞轮日志
    └── flywheel-YYYY-MM-DD.log
```
