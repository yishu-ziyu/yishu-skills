# 持续迭代机制

> Skill Eval Framework 的核心：发现问题 → 修复 → 验证 → 记录

## 迭代循环

```
┌─────────────────────────────────────────────────────────────┐
│                    ITERATION LOOP                             │
│                                                              │
│  EVAL →发现问题→ FIX → 验证 → 更新 evals.json → PUSH → 循环  │
└─────────────────────────────────────────────────────────────┘
```

## 迭代步骤

### 1. 运行评估
```bash
# 手动运行 Skill
~/.claude/skills/<skill-name>/scripts/<script>.sh <input>

# 检查输出
cat <output_file>
```

### 2. 发现问题
- [ ] 输出不符合预期？
- [ ] 有噪音/格式问题？
- [ ] 功能不工作？
- [ ] 缺少功能？

### 3. 修复问题
```bash
# 编辑 Skill 脚本或文档
nano ~/.claude/skills/<skill-name>/scripts/<script>.sh

# 或更新 SKILL.md
nano ~/.claude/skills/<skill-name>/SKILL.md
```

### 4. 验证修复
```bash
# 重新运行
~/.claude/skills/<skill-name>/scripts/<script>.sh <input>

# 检查是否修复
```

### 5. 更新评估记录
```bash
# 更新 evals.json
# - 添加新的测试用例
# - 记录修复的问题
# - 更新 pass rate
```

### 6. 推送到 GitHub
```bash
cd ~/Desktop/AI产品经理/agentic-assets

# 同步本地修改
rsync -av ~/.claude/skills/<skill-name>/ skills/<category>/<skill-name>/

# 提交
git add .
git commit -m "fix(<skill>): <修复描述>"
git push
```

## 问题追踪模板

```json
{
  "skill_name": "eve-transcriber",
  "version": "1.1.0",
  "iterations": [
    {
      "id": 1,
      "date": "2026-03-28",
      "issue": "输出包含 [1/4] 进度标记",
      "severity": "low",
      "fix": "添加 grep -vE '^\\[' 过滤",
      "verified": true,
      "pass_rate_before": "100%",
      "pass_rate_after": "100%"
    }
  ],
  "current_issues": [],
  "resolved_issues": 1
}
```

## 质量基线

| 指标 | 目标 | 最低可接受 |
|-------|------|-----------|
| Pass Rate | >90% | >70% |
| 执行时间 | <预期 | <2x 预期 |
| 输出质量 | 10/10 | 7/10 |

## 持续集成

每次推送自动检查：
1. evals.json 存在
2. 所有测试通过
3. 文档更新

---

## 示例：eve-transcriber 迭代记录

| 日期 | 版本 | 问题 | 修复 | 状态 |
|------|------|------|------|------|
| 2026-03-28 | v1.0.0 | 初始版本 | - | ✅ |
| 2026-03-28 | v1.1.0 | 输出有进度标记 | grep -vE '^\\[ | ✅ |
