---
name: research-charts
description: 当用户需要为研究工作流、数据分析、项目进度等场景创建图表可视化时触发。如"做一个阶段分布图"、"显示各类型的统计"、"做个KPI卡片"、"把数据做成表格"。创建时必须使用此 skill，按照 shadcn ChartContainer 封装模式和 Tufte 简洁原则，输出可直接复用的 TSX 组件。
---

# Research Charts - 数据可视化封装技能

## 核心理念：Tufte 原则

**Edward Tufte 的核心原则**：数据可视化应该简洁、清晰、优雅。一个图表只说一件事，说清楚。

1. **每个图表只说一件事** — 不要在一个图里堆太多信息
2. **去掉 chartjunk** — 无用的网格线、外框、装饰性元素一律去掉
3. **数据墨水比** — 图形中每一点都应该承载信息，删除不贡献信息的元素
4. **直接在图形上标注** — 不要靠图例解释，数据标签打在图形上
5. **必要时用数字而非图表** — 两个数字对比不需要图表，直接展示数字更清晰

## 技术栈

- **Recharts** — PieChart、BarChart、AreaChart 等所有图表底层
- **shadcn ChartContainer** — 统一包装，注入 CSS 变量支持 light/dark 主题
- **ChartConfig + ChartTooltip + ChartTooltipContent** — 必须通过 ChartContainer 注入，不能裸用 Recharts
- **CSS 变量** — 颜色用 `hsl(var(--chart-N))`，由 ChartConfig 自动注入

## UI 规范（按 Tufte 原则精简）

```
// ✅ 正确的：无边框，纯内容区
<div className="py-1">

// ❌ 旧规范（已废弃）：去掉 border p-4 外框
// <div className="rounded-lg border p-4">

// 图表标题（小一号，更轻量）
<h4 className="text-xs font-medium text-muted-foreground mb-3">
  图表标题
</h4>
```

## 图表类型选择决策树

```
数据是什么？
├── 1-2个大数字（对比/单指标）→ BigNumberCard（不用图表）
├── 少量离散分类对比（<5项）→ 横向进度条（CSS 实现，不用 Recharts）
├── 时间序列/连续数据 → Recharts 条形图/面积图
└── 超过5个分类/复杂数据 → Recharts 环形图/条形图
```

## 模式一：大数字卡片（最简洁）

当数据只有 1-2 个核心数字时，直接用数字 + 颜色 + 标签展示：

```tsx
export function BigMetricCard({ value, label, note, tone = "primary" }: BigMetricCardProps) {
  const toneClasses = {
    primary: "bg-primary/5 text-primary",
    destructive: "bg-destructive/5 text-destructive",
    success: "bg-success/5 text-success",
    warning: "bg-warning/5 text-warning",
  };

  return (
    <div className={`rounded-md p-3 ${toneClasses[tone]}`}>
      <div className="text-2xl font-bold tabular-nums mb-1">{value}</div>
      <div className="text-xs leading-relaxed">{label}</div>
      {note && <div className="text-[10px] text-muted-foreground mt-1">{note}</div>}
    </div>
  );
}
```

## 模式二：横向进度条（CSS 实现，不用图表库）

当数据是少量分类的数值对比（< 5项）时，用 CSS 进度条代替 Recharts：

```tsx
export function HorizontalBarChart({ data, maxValue }: HorizontalBarChartProps) {
  return (
    <div className="space-y-2">
      {data.map((item) => {
        const width = (item.value / maxValue) * 100;
        return (
          <div key={item.name} className="flex items-center gap-2">
            <div className="w-12 text-xs text-muted-foreground shrink-0">{item.name}</div>
            <div className="relative flex-1 h-4 bg-muted rounded-sm overflow-hidden">
              <div
                className="absolute inset-y-0 left-0 bg-primary/60 rounded-sm"
                style={{ width: `${width}%` }}
              />
              <div className="absolute inset-0 flex items-center px-2">
                <span className="text-xs font-medium tabular-nums">
                  {item.value}
                </span>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
```

## 模式三：精简 Recharts 条形图

当必须用 Recharts 时，去掉所有多余元素：

```tsx
// ✅ 正确：只留横线网格，去掉 border 外框，标签直接打在 bar 上
<ChartContainer config={chartConfig} className="aspect-[2.5/1] w-full">
  <BarChart data={data} margin={{ left: -20, right: 0, top: 4, bottom: 0 }}>
    {/* 只留横线，去掉竖线 */}
    <CartesianGrid horizontal vertical={false} strokeDasharray="3 3" />
    <XAxis dataKey="name" tickLine={false} axisLine={false} tickMargin={6} fontSize={11} />
    <YAxis tickLine={false} axisLine={false} tickMargin={6} fontSize={11} />
    <ChartTooltip content={<ChartTooltipContent />} />
    <Bar dataKey="value" fill="var(--color-项目名)" radius={[2, 2, 0, 0]} />
  </BarChart>
</ChartContainer>
```

## 模式四：数据表格（替代复杂图表）

当数据维度多、信息密集时，用表格比图表更清晰：

```tsx
<table className="w-full text-xs">
  <thead>
    <tr className="border-b">
      <th className="text-left font-medium text-muted-foreground pb-2">维度</th>
      <th className="text-left font-medium text-muted-foreground pb-2">数值</th>
      <th className="text-left font-medium text-muted-foreground pb-2">状态</th>
    </tr>
  </thead>
  <tbody className="divide-y">
    {rows.map((row) => (
      <tr key={row.key} className="hover:bg-muted/30">
        <td className="py-2 text-muted-foreground">{row.label}</td>
        <td className="py-2 font-medium tabular-nums">{row.value}</td>
        <td className="py-2">
          <span className={`rounded px-1.5 py-0.5 text-[10px] ${
            row.status === "低" ? "bg-success/10 text-success"
            : row.status === "高" ? "bg-destructive/10 text-destructive"
            : "bg-muted text-muted-foreground"
          }`}>
            {row.status}
          </span>
        </td>
      </tr>
    ))}
  </tbody>
</table>
```

## 创建步骤

1. **判断数据类型** — 用决策树选择合适的图表类型
2. **定义数据结构** — TypeScript 接口
3. **定义 ChartConfig**（如用 Recharts）— 每个数据系列一个 key，含 label 和 color
4. **组装组件** — 标题 + 核心数据 + 底部注释说明数据来源
5. **检查是否符合 Tufte 原则** — 能用一个数字说清楚就不用图表？能去掉网格线吗？

## 组件封装模式

### Props 接口

```typescript
interface PhaseDonutProps {
  items: DemoTimelineItem[]; // 统一数据结构
}
```

### 数据聚合函数

```typescript
function buildPhaseData(items: DemoTimelineItem[]) {
  const phases = [
    { label: "信息搜集", color: "hsl(var(--chart-1))" },
    { label: "研读文档", color: "hsl(var(--chart-2))" },
    { label: "交叉分析", color: "hsl(var(--chart-3))" },
    { label: "结论输出", color: "hsl(var(--chart-4))" },
  ];
  return phases.map((p, i) => {
    const phaseItems = items.filter((item) => item.phase === (i + 1) as 1|2|3|4);
    return {
      name: p.label,
      color: p.color,
      total: phaseItems.length,
      toolUse: phaseItems.filter((item) => item.type === "tool_use").length,
      toolResult: phaseItems.filter((item) => item.type === "tool_result").length,
      thinking: phaseItems.filter((item) => item.type === "thinking").length,
      text: phaseItems.filter((item) => item.type === "text").length,
    };
  });
}
```

## 标准化数据结构

```typescript
interface DemoTimelineItem {
  seq: number;
  type: "tool_use" | "tool_result" | "thinking" | "text" | "error";
  tool?: string;
  content?: string;
  input?: Record<string, string>;
  output?: string;
  phase: 1 | 2 | 3 | 4;
  phaseLabel: string;
}
```

## 参考实现

完整示例在：
- `references/component-templates.md` — 全部组件的完整 TSX（含 CSS 进度条、大数字卡片等新模式）
- `references/data-utils.md` — 数据聚合工具函数

## 常见错误

- ❌ `fill="#ff0000"` — 硬编码颜色，应该用 `hsl(var(--chart-N))`
- ❌ 直接用 `<PieChart>` — 必须用 `<ChartContainer config={...}>` 包装
- ❌ Tooltip 直接用 Recharts — 应该用 `<ChartTooltip content={<ChartTooltipContent />} />`
- ❌ 不传 items prop — 每个图表组件都接收统一的原始数据数组
- ❌ 用复杂图表展示简单数据 — 两个数字用 BigNumberCard，不需要图表
- ❌ 保留无用的竖向网格线 — 只留横向即可

## 导出清单

每个图表模块必须导出：
- 数据聚合函数（如 `buildPhaseData`）
- Props 接口（如 `PhaseDonutProps`）
- 组件（如 `PhaseDonutChart`）
