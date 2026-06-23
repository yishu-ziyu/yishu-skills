---
name: research
description: 完整的研究工作流顶层封装，整合 research-session（研究启动与过程管理）、research-report（研报写作）、research-charts（图表可视化）、research-to-slides（幻灯片演示）。当用户开始任何研究任务、论文写作、投资分析、学术研究时触发。
version: 1.0
actions:
  - id: session_start
    name: 研究启动（research-session）
    input: 用户模糊研究意图
    output: 结构化确认单（主题/目的/时长/产出形式）
    verify: 用户确认后才进入下一步
  - id: research_execution
    name: 研究执行
    input: 确认单 + 研究类型
    output: 研究成果（报告/分析/笔记）
    verify: 按类型分发至对应子workflow
  - id: report_write
    name: 研报写作（research-report）
    input: 确认单 + 研究成果
    output: 研报草稿（7章节MD）+ 审核报告
    verify: 审核Agent通过 + 用户确认
  - id: chart_generate
    name: 图表生成（research-charts）
    input: 研报草稿 + 数据点
    output: 可视化图表文件
    verify: 图表数量与描述一致
  - id: presentation_output
    name: 幻灯片输出（research-to-slides）
    input: 核心记忆点 + 研报结论
    output: output.html + speaking-notes.md
    verify: 记忆点清晰 + 数字比例正确
---

# Research Workflow

整合四个子模块的完整研究工作流：研究启动 → 执行研究 → 研报写作 → 图表生成 → 幻灯片输出。

## 子模块关系

```
research-session（研究启动与过程管理）
        ↓
research-report（研报写作，核心）
        ↓
research-charts（图表生成）
        ↓
research-to-slides（幻灯片演示）
```

## Action 流水线

---

### Action 1: 研究启动

**触发**：用户开始任何研究任务

**输入**：用户模糊意图
**输出**：结构化确认单
**验证**：用户明确确认

#### 收集信息（单次 AskUserQuestion）

```
Question 1 — 研究类型 (header: "类型"):
这是什么类型的研究？
- 投资研报 — 面向投资方的分析报告
- 学术研究 — 论文、答辩、理论学习
- 行业分析 — 市场、竞品、技术趋势
- 商业分析 — 公司、业务、产品

Question 2 — 研究目的 (header: "目的"):
研究的最终用途是什么？
- 投资决策 — 买入/不买，评估机会与风险
- 学术产出 — 论文发表、答辩准备
- 内部参考 — 团队分享、战略规划
- 知识整理 — 个人学习、笔记沉淀

Question 3 — 时间范围 (header: "时长"):
这次研究覆盖多大规模？
- 快速概览 — 1-2个核心发现，5分钟
- 标准研究 — 完整分析，15-30分钟
- 深度覆盖 — 全方位研究，60分钟以上

Question 4 — 已有材料 (header: "材料"):
你有哪些初始材料？
- 有文档/数据 — 请分享，我会提取关键信息
- 有大纲/笔记 — 请分享，我会补充细节
- 仅有问题 — 我来帮你梳理框架
```

#### 输出格式

```markdown
## 确认单

| 字段 | 值 |
|------|-----|
| 研究类型 | 投资研报 |
| 研究目的 | 投资决策 |
| 时间范围 | 标准研究（15-30分钟）|
| 已有材料 | 有文档 |
| 输出模块 | research-report |
```

---

### Action 2: 研究执行

**分发到对应子模块**

| 研究类型 | 子模块 | 说明 |
|---------|--------|------|
| 投资研报 | research-report | 完整7章节研报 |
| 学术研究 | research-session | 理论review + 笔记 |
| 行业分析 | research-session | 结构化分析 |
| 商业分析 | research-session | 商业画布 |

---

### Action 3: 研报写作

**输入**：确认单 + 研究成果
**输出**：研报草稿（7章节MD）+ 审核报告
**验证**：审核Agent通过 + 用户确认

#### 核心流程

```
阶段0: 格式规范提取（可选）
    ↓
阶段1: 研究检索Agent → Context Bundle
    ↓
阶段2: 写作Agent → 草稿文件
    ↓
阶段3: 审核Agent → 审核报告
    ↓
阶段4: 章节优化（可选）
    ↓
阶段5: README溯源更新
```

#### 7个标准章节

| 章节 | 核心问题 |
|------|---------|
| 第一部分 | 摘要与核心结论 — 评级/目标价/核心逻辑 |
| 第二部分 | 行业概览 — 市场是否真实且持续增长 |
| 第三部分 | 公司定位 — 公司是否具备实现需求的技术能力 |
| 第四部分 | 财务分析 — 财务数据是否验证业务逻辑 |
| 第五部分 | 估值分析 — 公司值多少钱 |
| 第六部分 | 风险提示 — 主要风险有哪些 |
| 第七部分 | 投资建议 — 最终推荐结论 |

---

### Action 4: 图表生成

**输入**：研报草稿 + 数据点
**输出**：可视化图表文件
**验证**：图表数量与描述一致

#### Tufte 精简原则

```
数据是什么？
├── 1-2个大数字 → BigNumberCard（不用图表）
├── <5类对比 → CSS横向进度条
├── 时间序列 → 条形图/面积图
└── 多维度数据 → 表格
```

---

### Action 5: 幻灯片输出

**输入**：核心记忆点 + 研报结论
**输出**：output.html + speaking-notes.md
**验证**：记忆点清晰 + 数字比例正确

#### 核心记忆点

每次汇报真正有意义的听众记忆最多3-5点。PPT的目标是让人走出会议室后记得关键数字、核心观点或行动建议。

---

## 用户介入点

| 介入点 | 时机 | 可做什么 |
|--------|------|---------|
| Action 1 确认后 | 研究前 | 修改主题、调整类型/目的 |
| Action 3 研报草稿后 | 写作中 | 修改章节、补充数据 |
| Action 4 图表生成后 | 可视化后 | 调整图表类型/数据 |
| Action 5 幻灯片后 | 演示前 | 修改记忆点、调整样式 |

---

## 质量检查清单

- [ ] 确认单用户已确认
- [ ] 每章节通过审核Agent把关
- [ ] 图表数量与描述一致
- [ ] 数据来源可追溯
- [ ] 记忆点数量符合时长要求
- [ ] 数字比例正确
- [ ] 审计记录已更新

---

## 目录结构

```
research/
├── SKILL.md                      # 本文件
├── research-session/
│   └── (research-session skill)
├── research-report/
│   └── (research-report skill)
├── research-charts/
│   └── (research-charts skill)
├── tests/
│   └── evals.json
├── scripts/
└── references/
```

## 版本迭代规则

- 每次用户反馈记录在审计文件中
- 当同一问题被反馈≥3次，启动 skill 重构
- 重构后版本号 +0.1
- 低效版本保留 2 个迭代周期后归档
