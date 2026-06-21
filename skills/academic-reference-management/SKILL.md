---
name: academic-reference-management
source: AI-compiled from academic methodology best practices
version: "2.0"
license: MIT
description: Guide the selection, evaluation, and formatting of references for academic papers and literature reviews. Use when compiling bibliographies, citing sources, reviewing reference quality, or addressing citation-related issues in scholarly writing.
---
# Academic Reference Management

## When to Use
- Compiling a bibliography or reference list
- Evaluating existing references for quality
- Deciding which sources to cite
- Formatting citations according to style guides
- Addressing citation ethics concerns

## When NOT to use

- 不适用于具体文献内容的深度阅读或分析
- 当用户没有提供足够信息来判断适用性时，先询问而非假设
- 如果已有更专门的 skill 覆盖当前场景，优先使用那个 skill
- 不要在时间极度紧迫时跳过 skill 的核心流程——宁可缩短范围也不要跳过必要步骤

## Core Functions of Citations

Understand why citations matter before making decisions:
1. **Research Foundation**: Demonstrates scientific basis and reflects research value
2. **Academic Integrity**: Shows inheritance of knowledge and respect for others' work
3. **Retrieval Value**: Enables readers to verify and explore sources

## Common Problems to Avoid

| Problem | Description | Fix |
|---------|-------------|-----|
| Incomplete listing | Missing key references | Cross-check against literature review scope |
| Excessive listing | Padding with irrelevant sources | Remove tangentially related citations |
| Too few citations | Insufficient evidence base | Expand literature search |
| Secondary sources | Citing without reading originals | Track down and cite primary sources |
| Outdated literature | Over-reliance on old sources | Prioritize recent publications |
| Non-standard formatting | Inconsistent style | Apply style guide systematically |
| Falsified references | Fabricated or inaccurate citations | Verify every citation exists and is accurate |
| Excessive self-citation | Disproportionate self-references | Limit to genuinely relevant own work |

## Selection Criteria (Best Practices)

Apply these criteria when deciding what to cite:

1. **Relevance**: Cite directly relevant literature only
2. **Recency**: Prioritize publications from the last 3-5 years
3. **Authority**: Favor peer-reviewed journals, established authors, highly-cited works
4. **Primary Sources**: Always cite original sources to avoid distortion
5. **Quality over Quantity**: Avoid reference stacking; focus on substantive citations
6. **Self-Citation**: Include your own work only when directly relevant
7. **Controversial Sources**: Use caution; acknowledge disputes when citing

## Execution Workflow

```
Step 1: Audit existing references
        → Check for completeness, relevance, recency

Step 2: Evaluate each reference
        → Apply selection criteria above
        → Flag: outdated, secondary, irrelevant sources

Step 3: Verify accuracy
        → Confirm each citation exists
        → Check quoted content matches source

Step 4: Format consistently
        → Apply required citation style (APA, MLA, Chicago, etc.)
        → Ensure uniform formatting throughout

Step 5: Final quality check
        → Verify all in-text citations appear in bibliography
        → Verify all bibliography entries are cited in text
```

## Reference Age Evaluation

Use the `reference_age` variable to assess recency:
- **0-3 years**: Current, highly preferred
- **3-5 years**: Recent, acceptable
- **5-10 years**: Acceptable for foundational or historical context
- **10+ years**: Use only for seminal works or historical background

## Output

A standardized list of high-quality, relevant, and accurately formatted references meeting academic standards.
---
## Gotchas

- **不要引用没读过的文献**：即使论文里引用了，自己没有通读过的文献不要列入参考文献——二手引用容易被原作者质疑
- **不要把"相关"当"必须引用"**：同一主题有 50 篇相关文献不是都要引，选 3-5 篇代表性 + 最新综述即可
- **不要忽略自引比例**：自引率 > 20% 会被期刊视为操纵引用，写入 Cover Letter 时要主动解释
- **不要把网络资源当学术引用**：博客、知乎、维基百科不可列入正式参考文献，最多放在脚注
- **不要混用引用格式体系**：GB/T 7714 的"顺序编码制"和"著者-出版年制"不能在同一篇论文里混用

---

## Risk Blacklist

- **伪造参考文献**：捏造作者、年份或页码，属于学术不端行为
- **二次引用不标注**：引用了二手转述而未标注"转引自"，被发现会被认定为剽窃
- **引用 predatory journal 的文章**： predatory journal 本身不可靠，引用它们会降低论文可信度
- **删除被引作者的反方观点**：只引用支持自己结论的文献，忽略反方证据
