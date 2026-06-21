# SKILL.md 编写指南

> 基于 [agentskills.io](https://agentskills.io) 规范

## 基础结构

```yaml
---
name: skill-name
description: >
  技能描述。说明这个技能做什么，以及何时使用。
  包含具体触发短语，方便 Agent 识别。
---

# Skill 名称

## 简介
一句话描述技能功能。

## 触发词
- "触发词1"
- "触发词2"

## 使用方式
### 基本用法
```

## Frontmatter 必需字段

| 字段 | 说明 | 示例 |
|------|------|------|
| `name` | 小写字母、数字、连字符 | `eve-transcriber` |
| `description` | 最多 1024 字符 | `使用 Qwen3-ASR 进行本地语音转文字...` |

## Description 写法

### ✅ 正确格式

```yaml
description: >
  Creates and writes professional README.md files for software projects.
  Use when user asks to "write a README", "create a readme", 
  "document this project", "generate project documentation".
```

### ❌ 错误格式

```yaml
# 描述太模糊
description: Helps with documents.

# 描述工作流而非触发条件
description: Use when executing plans - dispatches subagent per task
```

### 核心原则

**结构**: `[技能做什么] + [何时使用，包含具体触发短语]`

1. **说明功能**: 技能能做什么
2. **列出触发词**: 用户可能说的话
3. **保持简洁**: 最多 1024 字符

## 目录结构

```
skill-name/
├── SKILL.md           # 必需：指令 + YAML 元数据
├── scripts/           # 可选：可执行脚本
├── references/        # 可选：按需加载的文档
└── assets/           # 可选：模板、图片
```

## 三层加载系统

| 层级 | 何时加载 | Token 消耗 | 内容 |
|------|----------|-----------|------|
| **Level 1: 元数据** | 始终加载 | ~100 tokens | name + description |
| **Level 2: 指令** | Skill 触发时 | <5k tokens | SKILL.md 主体 |
| **Level 3: 资源** | 按需加载 | 无限制 | scripts 执行不加载内容 |

## 最佳实践

### 1. 确定性操作放进脚本

需要一致性的操作 → 放进 `scripts/`：

```bash
# ✅ 好的：确定性评分
A3_PASS=false
if [ ${#A3_FOUND[@]} -gt 0 ]; then
  A3_PASS=true
fi

# ❌ 坏的：让 Agent 自己判断
# Agent 可能会做出不一致的决定
```

### 2. 使用 MUST/NOT 而非建议

```markdown
## 严格规则
- Never override, adjust, or recalculate any score
- Never add or remove checks from the report
```

### 3. 渐进式披露

```markdown
## 完整流程（需要时展开）

<details>
<summary>详细步骤</summary>

### Step 1: 准备环境
...

</details>
```

### 4. 工作流清单

```markdown
## 工作流程

Copy this checklist and check off items as you complete them:

- [ ] Step 1: 准备
- [ ] Step 2: 执行
- [ ] Step 3: 验证
```

## 资源链接

- [Agent Skills 规范](https://agentskills.io)
- [Anthropic Skills 仓库](https://github.com/anthropics/skills)
- [编写指南](https://engineering.block.xyz/blog/3-principles-for-designing-agent-skills)
