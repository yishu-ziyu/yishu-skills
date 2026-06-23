# Claude Skills

记录个人常用 Claude Skills 的技能库，持续完善。

## 目录结构

```
claude-skills/
├── research/                     # 完整研究工作流
│   ├── SKILL.md               # 顶层封装
│   ├── research-session/       # 研究启动与过程管理
│   ├── research-report/       # 研报写作
│   ├── research-charts/        # 数据可视化
│   └── tests/evals.json
│
└── research-to-slides/          # 幻灯片演示输出
    ├── SKILL.md
    ├── README.md
    └── tests/evals.json
```

## 工作流概览

```
research-session（研究启动）
        ↓
research-report（研报写作）
        ↓
research-charts（图表生成）
        ↓
research-to-slides（幻灯片演示）
```

## 核心原则

- **验证驱动** — 每个 Action 有明确的验证条件，未通过不进入下一步
- **用户可控** — 每个 phase 结束后有确认点，不满意随时修改
- **迭代优化** — 审核 Agent 把关，反馈注入，再推理直到收敛

## 主要 Skills

| Skill | 说明 |
|-------|------|
| research | 顶层工作流，整合4个子模块 |
| research-report | 3 Agent 协作研报写作 |
| research-session | 研究启动与过程管理 |
| research-charts | Tufte 原则数据可视化 |
| research-to-slides | 记忆点驱动幻灯片演示 |
