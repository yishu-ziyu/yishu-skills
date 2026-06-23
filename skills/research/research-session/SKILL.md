---
name: research-session
description: |
  完整的研究/学术工作流，整合context-confirm + theory-review + incremental-save。
  当用户开始任何研究任务、论文工作、理论学习、学术review时触发。
  典型场景：准备论文/答辩、复习考试、整理笔记、理解复杂理论、进行知识合成。
  也适用于：用户说"开始研究"、"做学术review"、"复习理论"、"准备答辩"。
  这是最常用的研究workflow，确保每个研究session都有结构化的开始、过程和结束。
---

# Research Session Skill

## 核心编排

此skill自动整合以下三个基础skill：

1. **context-confirm** → 确保研究环境正确
2. **theory-review** → 执行深度理论review
3. **incremental-save** → 每个概念后保存进度

## Session工作流

### Phase 1: 启动确认（来自 context-confirm）

**立即执行**：

```
在开始研究之前，快速确认：

1. **研究主题**：你要研究/复习的是什么？（给我一个主题或问题）
2. **研究目的**：是为了论文/答辩/考试/个人理解？
3. **时间范围**：这次想cover多少内容？（一个概念/一个章节/全部）
4. **输出形式**：需要什么形式的产出？（笔记/quotes/思维导图/口头报告）
```

### Phase 2: 结构化Review（来自 theory-review）

**使用渐进式clarification循环**：

1. **初始探索**：了解当前理解程度
2. **概念分解**：将主题分解为3-5个核心概念
3. **逐一review**：对每个概念：
   - 解释核心定义
   - 提供关键quotes
   - 给出具体案例
   - 检查理解
4. **保存进度**：每个概念后调用 incremental-save

### Phase 3: 增量保存（来自 incremental-save）

**保存时机**：
- 每个核心概念完成时
- session中段检查点
- session结束前（必须！）

**保存到**：
```
review_notes/[研究主题]/
├── session_YYYYMMDD_HHMM.md
├── concepts/
│   ├── 001_[概念1].md
│   ├── 002_[概念2].md
│   └── ...
└── progress_summary.md
```

### Phase 4: Session结束

**结束前必须**：
1. 保存当前进度
2. 列出"下次继续"清单
3. 确认下一步
4. 告知用户如何恢复

```
✅ 研究Session完成

📍 进度: X/Y 概念
📁 保存位置: review_notes/[主题]/
📋 下次继续:
   1. [第一件待办]
   2. [第二件待办]
💬 下次开始时说"继续研究 [主题]"即可恢复
```

## 特殊场景

### 长时间研究
→ 每45-60分钟提醒保存
→ 如果session可能中断，提前告知用户

### 研究中遇到新问题
→ 记录到 "questions.md"
→ 标注为"待后续clarification"

### 用户要求停止
→ 立即保存当前进度
→ 总结已完成内容
→ 确认保存位置

## 与其他skill的配合

- **incremental-save** 在每个concept后自动触发
- **theory-review** 的clarification循环适用于每个概念
- **output-anchor** 可在最终产出时提供完整信息

## 避免的事项

- 不要跳过context-confirm直接开始
- 不要在未保存进度的情况下结束
- 不要试图一次cover太多内容
- 不要在用户还没理解基础概念前引入新内容
