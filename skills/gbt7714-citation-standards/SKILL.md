---
name: gbt7714-citation-standards
source: AI-compiled from GB/T 7714-2015 national standard
version: "2.0"
license: MIT
description: Apply GB/T 7714-2015 citation standards for Chinese academic documents. Use this skill when formatting bibliographic references, choosing between sequential coding or author-year systems, or assigning document type codes.
---
# GB/T 7714-2015 Citation Standards

Use this skill to format citations and references according to China's national bibliographic standard GB/T 7714-2015. This skill covers both citation systems, document type codes, and common error prevention.

## When to Use

- Formatting in-text citations and reference lists
- Choosing between Sequential Coding or Author-Year system
- Assigning correct document type and carrier codes
- Checking references for common formatting errors

## When NOT to use

- 不适用于非 GB/T 7714 标准的引用格式（如 APA、MLA）
- 当用户没有提供足够信息来判断适用性时，先询问而非假设
- 如果已有更专门的 skill 覆盖当前场景，优先使用那个 skill
- 不要在时间极度紧迫时跳过 skill 的核心流程——宁可缩短范围也不要跳过必要步骤

## Citation System Selection

### Sequential Coding System (顺序编码制)

Use when the paper adopts numbered citations.

**In-Text Citation Rules:**
- Single citation: [1]
- Multiple citations: [3, 9, 15]
- Continuous range: [5-6] (connect with hyphen)
- Repeated citation (same page): Use original number [2]
- Repeated citation (different page): [2]260

**Reference List Rules:**
- Order: By first appearance in text
- Numbering: Continuous from [1] to end

### Author-Year System (著者-出版年制)

Use when the paper adopts author-name citations.

**In-Text Citation Rules:**
- Format: (Author, Year)
- Western authors: Surname only
- Chinese/Korean/Japanese authors: Full name or surname
- Corporate authors: Organization name
- Narrative citation: Author name in text, (Year) only
- Multiple authors (Western): First author + 'et al.'
- Multiple authors (Chinese): First author + '等'
- Same author, same year: 2021a, 2021b
- Repeated with different page: (Author, 1996)1194

**Reference List Rules:**
1. Group by language: Chinese, Japanese, Western, Russian, Others
2. Within each group: Sort alphabetically by author name, then by year

## Document Type Codes

Assign the correct code based on source type:

| Document Type | Code |
|---------------|------|
| Ordinary Book | M |
| Proceedings/Conference | C |
| Compilation | G |
| Newspaper | N |
| Journal | J |
| Dissertation | D |
| Report | R |
| Standard | S |
| Patent | P |
| Database | DB |
| Computer Program | CP |
| Electronic Bulletin | EB |
| Archive | A |
| Map | CM |
| Dataset | DS |
| Other | Z |

## Electronic Carrier Codes

| Carrier Type | Code |
|--------------|------|
| Magnetic Tape | MT |
| Disk | DK |
| CD-ROM | CD |
| Online Network | OL |

**Combination Example**: [J/OL] for Online Journal

## Common Errors to Avoid

### 1. Number and Punctuation Irregularity
- Problem: Mixing Chinese and Arabic numerals inconsistently
- Rule: Use the SAME coding system consistently throughout the article and journal

### 2. Annotation Position Errors
- Pre-annotation (前标注): Marked BEFORE the citation content
- Post-annotation (后标注): Marked AFTER the citation content
- Rule: Position must be appropriate and accurate

### 3. Arrangement Disorder
- Verify: Each reference appears in the main text
- Verify: Order of appearance matches the reference list order

## Verification Checklist

- [ ] Consistent coding system throughout document
- [ ] Correct document type codes assigned
- [ ] Electronic carrier codes combined properly
- [ ] Annotation positions are appropriate
- [ ] Reference list order matches in-text citation order (for sequential system)
- [ ] Reference list sorted correctly (for author-year system)
---
## Gotchas

- **不要把 [J/OL] 和 [EB/OL] 混用**：在线期刊用 [J/OL]，电子公告用 [EB/OL]，载体代码与文献类型必须匹配
- **不要忽略同一文献不同格式的区分**：纸质版和网络版的标识不同，同一篇文章如果同时存在两种载体，引用时要择一
- **不要把责任者写全**：GB/T 7714 规定西文作者只写姓+首字母缩写，不要写全名
- **不要漏标文献类型标识**：会议论文是 [C]，学位论文是 [D]，标准是 [S]，一个字母错会被退改
- **不要把著者-出版年制的文献按顺序编码制排列**：两种体系的参考文献列表排序规则不同

---

## Risk Blacklist

- **擅自更改 GB/T 7714-2015 的格式规范**：这是国家标准，不是风格偏好
- **在参考文献中混入未正式发表的成果**：工作论文、私人通讯不能列入正式参考文献
- **复制文献题名时保留原始大写**：中文文献题名转写为英文时，首字母大写其余小写
