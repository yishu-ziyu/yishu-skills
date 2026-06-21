---
name: academic-peer-review-workflow
source: AI-compiled from academic methodology best practices
version: "2.0"
license: MIT
description: Guide manuscripts through multi-round academic peer review process from submission to acceptance. Use when a manuscript is submitted to an academic journal, when tracking review status across multiple rounds, when determining appropriate actions based on review conclusions (revise-and-resubmit, acceptable, reject), or when preparing manuscripts for editorial final review.
---
# Academic Peer Review Workflow

## When to Use
- A manuscript is submitted to an academic journal
- Tracking manuscript status through review rounds
- Determining next steps based on review conclusions
- Preparing for editorial final review

## When NOT to use

- 不适用于作者自身的论文撰写阶段（专注于审稿流程管理）
- 当用户没有提供足够信息来判断适用性时，先询问而非假设
- 如果已有更专门的 skill 覆盖当前场景，优先使用那个 skill
- 不要在时间极度紧迫时跳过 skill 的核心流程——宁可缩短范围也不要跳过必要步骤

## Prerequisites
- Submitted manuscript
- Available reviewers
- Editorial board in place

## Workflow Stages

### Round 1 - Initial Peer Review

1. **Peer reviewers evaluate the manuscript**
2. **Determine conclusion from possible outcomes:**
   - `修后再审` (Revise and resubmit): Major revisions required, will return for re-review
   - `可刊用` (Acceptable): Minor revisions needed, acceptable for publication
   - `拒稿` (Reject): Not suitable for publication

3. **If '修后再审':**
   - Author receives reviewer comments and editorial feedback
   - Author prepares detailed response and revised manuscript
   - Manuscript returns to reviewers for second evaluation

### Round 2 - Second Review

1. **Reviewers evaluate revised manuscript**
2. **Determine conclusion:**
   - `修后再审`: Further revisions needed, continue revision cycle
   - `可刊用`: Acceptable after revisions, proceed to editorial review

### Editorial Final Review (定稿会终审)

1. **Editorial board conducts comprehensive review**
2. **Address common requirements:**
   - Language expression improvements
   - Reduce text similarity ratio (typically to under 10%)
   - Add author information, affiliations, funding details
3. **Outcomes:**
   - Additional revision requests if issues persist
   - `同意录用` (Agree to publish)

### Multiple Editorial Rounds

If issues persist (similarity ratio exceeds standard, language problems remain):
- Editorial board issues additional revision requests
- Author must address each specific concern
- Process repeats until requirements met

### Final Acceptance

**When all requirements satisfied:** `审稿结论：同意录用`

**Additional requirements may include:**
- Expand Chinese abstract to 500-800 characters
- Corresponding English abstract modifications

## Key Variables to Track

| Variable | Type | Description |
|----------|------|-------------|
| review_conclusion | enum | Current status: 修后再审/可刊用/同意录用/拒稿 |
| round_number | integer | Current review round number |
| similarity_ratio | percentage | Text similarity/copy ratio percentage |
| abstract_length | integer | Required abstract word count |

## Constraints
- Workflow may vary by journal
- Number of rounds can differ (typically 2-4 rounds for accepted papers)
- Some journals use single-blind or double-blind review

## Decision Summary

At each stage, the workflow produces a review conclusion that guides whether the manuscript proceeds, requires revision, or is rejected.
---
## Gotchas

- **不要把"修后再审"当成终审**：R1 修后再审后 R2 仍有拒稿风险，不要在第一轮修回时假设"改完就能过"
- **不要混淆单盲和双盲审稿的沟通规则**：单盲期刊可以直接联系编辑，双盲期刊作者回复中不能泄露身份
- **不要跳过相似度检查**：中文期刊普遍要求总复制比 < 10-15%，改完后必须用知网/万方检测，不能凭感觉判断
- **不要把审稿意见当"必须全部照做"**：有些意见可以礼貌地解释为什么不改，关键是论证逻辑自洽
- **不要忽略定稿会的隐性门槛**：除了语言和重复率，很多期刊在定稿会还会卡"基金项目"和"作者职称"等非学术因素

---

## Risk Blacklist

- **伪造审稿意见或自行修改审稿人姓名**：学术不端，一旦发现直接列入黑名单
- **在同一期刊同时投递同一主题的多篇论文**：属一稿多投变体，多数期刊检测到后会封杀作者
- **用 AI 润色后不声明**：部分期刊要求 AI 辅助使用声明，隐瞒可能被视为学术不端
- **在回复信中攻击审稿人**：即使审稿意见不合理，保持专业语气，否则可能直接被拒
