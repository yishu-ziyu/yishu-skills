# 叙事游戏设计 Skill 速查表 v2

> 从 87 个《游戏设计艺术》Skill 中筛选出做叙事/互动小说/视觉小说时真正会用到的。
> 版本：v2.0（补充了调研中发现的关键原则）

---

## 开发前：定创意

| Skill | 什么时候用 | 一句话 |
|---|---|---|
| `creative-ideation-process` | 项目启动，脑子空白 | 创意生成与概念提炼方法论 |
| `secret-purpose-lens` | 不确定这个创意值不值得做 | 自我反思，确保行动与深层价值一致 |
| `elemental-tetrad-analysis` | 概念验证，判断创意有没有硬伤 | 四元素分析：美学 / 机制 / 故事 / 技术 |
| `game-design-evaluation-framework` | 做了 2-3 版原型后，选最好的方向 | 八项测试框架评估设计质量 |

**调研补充原则**：
- 先定总时长（"30 分钟一局"），用时长做范围控制
- 冷开场适合悬疑（省铺垫），暖开场适合角色驱动（多情感投入）

---

## 开发中：做设计

| Skill | 什么时候用 | 一句话 |
|---|---|---|
| `theme-narrative-character-design` | 定世界观、角色关系和故事主题 | 主题 / 叙事 / 角色设计工具集 |
| `character-design-framework` | 需要系统化创建角色时 | 角色属性、性格钻石、关系网络 |
| `character-structure-planning` | 规划角色阵容和发展轨迹 | NPC 名单、角色弧光 |
| `game-mechanics-design` | 设计玩法机制和数值 | 机制设计、平衡数值、概率计算 |
| `game-mechanics-systems` | 机制之间如何联动 | 基础结构、规则、目标系统、反馈 |
| `game-objects-state-management` | 设计物品/状态/进度系统 | 实体属性、状态管理、可见性规则 |
| `puzzle-design-principles` | 做解谜元素时 | 谜题设计十大原则 |
| `time-mechanics-design` | 需要时间系统（回合/倒计时/节奏） | 离散 / 连续 / 混合时间系统 |
| `interface-mapping-architecture` | 设计 UI/输入系统 | 物理和虚拟层之间的映射 |

**调研补充原则**：
- 分支用**重复菱形**结构：复用结构，换内容
- Defining 选择 ≤ 2 个（改变结局），Rerouting 选择多做（改变路径）
- 信息流用三层架构：表面证据 → 推理连接 → 隐藏叙事

---

## 开发中：做叙事

| Skill | 什么时候用 | 一句话 |
|---|---|---|
| `game-communication-design` | 信息怎么呈现给玩家 | 游戏与玩家之间的信息传递结构 |
| `player-motivation-flow` | 不知道玩家为什么会沉迷 | 动机、乐趣、好奇心与心流体验 |
| `game-pleasures-taxonomy` | 优化体验的"爽点" | LeBlanc 玩家乐趣分类法 |
| `character-trait-expression` | 写角色对话 | 通过对话、动作表达性格特征 |
| `character-status-dynamics` | NPC 之间有地位关系 | 基于地位的行为动态（支配/顺从） |

**调研补充原则**：
- 每个场景的微结构：铺垫(15-25%) → 冲突(50-60%) → 解决(15-25%)
- 交替长短场景——短的建速度，长的给分量
- "Show don't tell"预算方案：静态场景+音频+文字排版 > 动画+过场

---

## 测试阶段：调体验

| Skill | 什么时候用 | 一句话 |
|---|---|---|
| `iterative-game-development` | 每次迭代规划 | 快速原型、风险评估、迭代方法 |
| `playtesting-type-selection` | 决定用什么方式测试 | 四种测试类型（可用性/平衡/享受/对比） |
| `playtesting-execution-protocol` | 组织正式试玩 | 开场白、观察方法、开发者出席决策 |
| `playtesting-organization-and-location` | 找测试者和场地 | 测试计划、地点选择 |
| `design-quality-evaluation` | 整体评估设计质量 | Alexander 十五属性框架 |

**调研补充原则**：
- Day 1 就做 debug 工具（场景跳过 + 变量控制 + 覆盖率追踪）
- 分支游戏的测试清单："你触发了哪些结局？看到了哪些场景？"
- 文字量预估 ×2（分支会放大实际工作量）

---

## 范围控制（来自 postmortem 调研，非 Skill 但至关重要）

| 规则 | 原因 |
|---|---|
| 结局 ≤ 3 个 | 每个结局指数级增加 QA 工作量 |
| 先定固定时长 | "尽量丰富"没有约束力，"30 分钟"有 |
| 每个选择都要有存在的理由 | 删掉一个选择不影响体验 = 这个选择不该存在 |
| MVP 门禁 | "支持 MVP → 做；不支持 → v2 列表" |

---

## 不常用但值得知道

| Skill | 一句话 |
|---|---|
| `world-building-strategy` | 世界观构建，做宏大叙事时用 |
| `mmo-narrative-design` | MMO 叙事，持久世界选择权重 |
| `asymmetric-game-design` | 非对称设计（玩家能力不对等） |
| `transmedia-world-design` | 跨媒体 IP 开发 |
| `ethical-game-design` | 内容伦理，涉及暴力/敏感题材时参考 |

---

## 完整索引

全部 Skill 在本目录 `skills/`，索引是 `index.md`。
