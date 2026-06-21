# Skill Eval Framework

> 基于 AutoResearch 思想的 Skill 评估框架

## 核心思想

AutoResearch 的核心机制是：**快速实验 + 量化指标 + 迭代优化**

```
AUTORESEARCH LOOP:
1. 修改代码
2. 运行实验 (固定时间预算)
3. 检查指标 (val_bpb)
4. 记录结果 (keep/discard)
5. 迭代优化
```

类比到 Skill 评估：

```
SKILL EVAL LOOP:
1. 定义触发词 + 期望输出
2. 运行 Skill
3. 检查指标 (成功率、质量分数)
4. 记录结果 (pass/fail)
5. 迭代优化 Skill
```

## 评估指标

| 指标 | 描述 | 目标 |
|------|------|------|
| **成功率** | Skill 正确响应触发词的比例 | >80% |
| **质量分数** | 输出质量评分 (1-10) | >7 |
| **覆盖率** | Skill 能处理的场景比例 | >70% |
| **执行时间** | Skill 完成任务的平均时间 | 越短越好 |

## Eval Schema

```json
{
  "skill_name": "skill-name",
  "version": "1.0.0",
  "evals": [
    {
      "id": 1,
      "name": "测试名称",
      "prompt": "触发 Skill 的输入",
      "expected_output": "期望的输出描述",
      "success_criteria": {
        "criterion_1": true,
        "criterion_2": true
      },
      "actual_output": {},
      "result": "PASS|FAIL",
      "notes": "备注"
    }
  ],
  "summary": {
    "total_evals": 3,
    "passed": 2,
    "failed": 1,
    "pass_rate": "66.7%"
  }
}
```

## 评估流程

1. **准备阶段**
   - 选择要评估的 Skill
   - 定义测试用例 (prompts + expected outputs)
   - 准备测试数据 (音频、文档等)

2. **执行阶段**
   - 运行 Skill against each eval
   - 记录实际输出
   - 记录执行时间和错误

3. **评估阶段**
   - 对比 actual vs expected
   - 判断 pass/fail
   - 计算指标

4. **迭代阶段**
   - 分析失败案例
   - 优化 Skill 描述
   - 更新 evals

## 示例：eve-transcriber 评估

```bash
# 评估结果
total_evals: 1
passed: 1
failed: 0
pass_rate: 100%

# 问题
- 输出中包含 [1/4] 进度标记

# 改进建议
- 添加输出过滤，移除进度标记
```

## 运行评估

```bash
# 方法1: 手动运行
~/.claude/skills/eve-transcriber/scripts/transcribe.sh <audio_file>

# 方法2: 批量评估
# (待实现: 评估脚本)
```

## 下一步

1. 为每个 Skill 创建 evals.json
2. 实现自动化评估脚本
3. 建立 pass rate 基线 (目标 >80%)
4. 持续迭代优化
