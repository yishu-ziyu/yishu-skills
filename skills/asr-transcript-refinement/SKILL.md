---
name: asr-transcript-refinement
description: Use when transcribing audio (podcast/video audio/meeting) into clean Chinese paragraph form. Two modes — speed-first (default, ~15 min for 1 hr audio on M2) with FunASR + single LLM cleanup, and rigorous (opt-in, ~60-90 min) with multi-agent producer-reviewer for 100% accuracy. Two backends — FunASR local (default, free) and Stepfun cloud stepaudio-2.5-asr (opt-in via STEP_API_KEY, 0.15 元/小时)
---

# ASR Transcript Pipeline

> **v3 (2026-06-12)** — Dual mode × Dual backend. FunASR is default, Stepfun cloud is opt-in.

## Overview

End-to-end audio → clean transcript pipeline. Default uses **FunASR + SenseVoice-Small 全精度**（官方 ModelScope）做 ASR，main thread 跑一遍 LLM cleanup 应用「100% 上下文确证」规则。Long audio（>10min）自动 ffmpeg 切分，sub-agent 并行转写。

**Optional cloud backend**: [Stepfun 阶跃星辰 `stepaudio-2.5-asr`](https://platform.stepfun.com)（Step Plan 订阅）— 0.15 元/小时，启用方法 `export STEP_API_KEY=...` 即可自动切换。

**Core principle**: 留口误比瞎猜准 — preserve speaker fragments rather than paraphrase. Only fix ASR errors with 100% contextual confidence.

## Quick Decision（LLM 第一步必须问）

**收到"转录这个音频"时不要直接跑命令，先问用户 2 个问题决定 backend**：

| 决策 | 单选 | 推荐 backend |
|------|------|--------------|
| **1. 说话人数量？** | 单人（独白 / 单主播 / 视频音轨解说）<br>多人（对话 / 访谈 / 圆桌 / 多人播客） | 单人 → **Stepfun cloud**（快 2-3x，便宜 0.15 元/h）<br>多人 → **FunASR local**（带 `cam++` 说话人分离） |
| **2. 时长？** | < 10min<br>≥ 10min | 不切分<br>ffmpeg 自动切 10min chunks |

**为什么不直接 default**：FunASR 多人说话人分离是**唯一**关键差异。Stepfun 没有 cam++ 模型，多人音频会全部标 `Speaker 0`（实测，2026-06-12）。单人音频用 FunASR 是杀鸡用牛刀，浪费 GPU 时间。

**默认推荐**（用户不想回答时）：**本地 FunASR**——质量上限更高，单人也能用，但速度比 Stepfun 慢 2-3x。

**询问模板**（复制即用）：
> 转录前先问 2 个：
> 1. 录音是**单人**还是**多人**？决定用本地（多人必备）还是云端（单人快 2-3x）。
> 2. **多长**？< 10min 不切分，≥ 10min 自动切。
>
> 不想答的话默认走本地 FunASR。

## When to Use

- 任何长度的音频文件（播客 / 抖音 B站视频音轨 / 会议录音）
- 中文为主，FunASR 也支持 50+ 语言
- 输出想要段落形式、不要 SRT 时间戳

**Don't use when:**

- 实时流式转写（用 streaming ASR 方案）
- 已经有干净文稿（直接 skip）
- 需要翻译（这是另一个 task）
- 单词汇量 / 字幕嵌入（直接 SRT 输出）

## Two Modes

| 维度 | **Speed-first**（默认） | **Rigorous**（opt-in） |
|------|------------------------|----------------------|
| ASR 模型 | FunASR SenseVoice-Small FP | 同 |
| 切分 | >10min 自动切 | 手动 ≥5 段 |
| ASR 阶段 | Sub-agent 并行 | 单 agent 串行 |
| LLM review | Main thread 单 pass | Producer ×3 + Reviewer ×3 交叉 |
| 1 小时音频总耗时 | ~15 min（M2） | ~60-90 min |
| 质量 | 90%（LLM cleanup 后） | 99%（人工 spot-check 后） |
| 适用场景 | 播客 / 视频 / 日常 | 法律 / 医疗 / 学术 / 出版 |

**默认走 speed-first**。需要 rigorous 时显式声明（"这个用 rigorous 模式"）。

## Speed-First Workflow

```
输入：单音频文件（任何长度）
  │
  ├─ < 10 min ─────────────────────────────────────────┐
  │                                                     │
  └─ ≥ 10 min ──→ ffmpeg 切 10min chunks ──┐           │
                                              │           │
                                              ▼           ▼
                              派 N 个 sub-agent 并行转写：
                              每个 agent 跑 transcribe_chunk.py
                              输出 SRT + 纯文本到中间目录
                                              │
                                              ▼
                              Main 收集 SRT/TXT
                                              │
                                              ▼
                              LLM cleanup（单 pass）：
                              - 应用「100% 上下文确证」规则
                              - 删除时间戳，合并为段落
                              - 标注存疑点
                                              │
                                              ▼
                              verify.sh：grep 已知坏模式
                                              │
                                              ▼
                              ~/Desktop/即时学习/<audio-slug>/transcript.md
                              (多 part: part1.md / part2.md / ...)
```

### Sub-agent Dispatch Pattern

Main 跑 `split.sh` 切完，列出去 N 个 chunk，然后**一次性 dispatch N 个 sub-agent**（Agent 工具），每个 agent 收到 prompt：

```
你是转写 agent #N/M。
- 输入：/path/to/chunk_NN.wav（10min 16kHz mono WAV）
- 输出：/path/to/chunk_NN.srt 和 /path/to/chunk_NN.txt
- 脚本：bash transcribe_chunk.py /path/to/chunk_NN.wav /path/to/chunk_NN
- 激活 venv：source /path/to/.venv-funasr/bin/activate
- 不要改 FunASR 输出（ITN 已经做了基础规范化）
- 不要合并、不要删时间戳、不要"修正"任何东西
- 完成后报告：处理时长、SRT 行数、是否遇到错
```

Sub-agent 1 Write = 1 个 chunk，避免长操作。

## Rigorous Workflow（opt-in，仅当显式声明时使用）

原 v1 流程保留：

```
1. PRE-PROCESS: Strip SRT timestamps, merge cross-line fragments
2. GOLD STANDARD: Refine ONE segment → show user → get approval
3. PHASE 1 - PRODUCERS (parallel):
   N agents, each handles ≤3 files
4. PHASE 2 - REVIEWERS (parallel, CIRCULAR cross-review):
   N independent agents — A reviews B, B reviews C, C reviews A
5. WRAP-UP: grep for systematic ASR patterns, sed batch fix
6. VERIFY: grep timestamps=0, known-bad-terms=0
```

保留原因：法律/医疗/学术/出版场景，60-90 分钟的耗时换 100% 准确值得。**默认不跑这个**。

## Scripts

| 脚本 | 用途 | 何时跑 |
|------|------|--------|
| `scripts/setup.sh` | 创建 venv + 装 FunASR + 预热模型 | 首次使用（FunASR backend） |
| `scripts/split.sh` | ffmpeg 切 10min chunks | 主线程，转写前 |
| `scripts/transcribe_chunk.py` | FunASR per-chunk 转写（local） | Sub-agent 跑（默认 backend） |
| `scripts/transcribe_stepfun.py` | Stepfun cloud ASR per-chunk | Sub-agent 跑（设了 `STEP_API_KEY` 时） |
| `scripts/merge.py` | 合并 SRT + TXT（按时间戳） | 主线程，转写后 |
| `scripts/verify.sh` | grep 已知坏模式 + 时间戳残留 | 主线程，cleanup 后 |
| `scripts/pipeline.sh` | 一键跑完 speed-first 全流程 | 快速验证 |
| `scripts/cleanup.sh` | 删 ASR 中间产物（chunks/*.wav），保留 merged/ | 最终 `.md` 写完后 |

**重要**：用户机器上 **MPS 加速的 FunASR** 是最常见路径，setup.sh 装好就能用。**不要**用 sherpa-onnx int8 替代——那是 v1 的"次等"方案。

## Output Format

Cleanup 后的 `.md` 文件**统一格式**——YAML frontmatter + 简化段落结构：

```markdown
---
date: 2026-06-12
source: 20260609_012544_part1.m4a
duration: 66min
backend: FunASR SenseVoice-Small + cam++
speakers: 4 (Speaker 0/1/2/3)
notes: 4 人对谈；`[存疑：xxx]` 表示 ASR 无法 100% 确证
---

# 20260609_012544_part1

## 开场：[主题]

**Speaker 1:** [内容...]

## Q1：[问题]？

**Speaker 2:** [内容...]
—— [追问]？
**Speaker 2:** [回应]

**Speaker 0:** [内容...]
```

**结构原则**：
- **元信息 → frontmatter**（不在正文 blockquote）
- **每节前后不写 `---`**（H2 标题已能视觉分组）
- **Speaker 用 `**Speaker N:**` 加粗前缀**，每段开头一次；不写 `### Speaker X：副标题`（和 `**Speaker N:**` 重复）
- **H1 = 文件名**，去掉"完整转录稿"后缀
- **`[存疑：xxx]` inline 标注**（不单列块、不写"概述"段）
- **关键术语加粗**（不写"首先/其次/最后"八股）

**Hygiene 自检**（cleanup pass 完成后必跑）：
- 时间戳残留 `[HH:MM:SS]` = 0
- Speaker 标签数 ≥ N（对话参与人数）
- Q 主题节数 ≥ 5
- `---` 只在 frontmatter 闭合之后**不**出现
- 不出现 `### Speaker X：副标题` 模式

## Output Location

**走法 B:一音频一文件夹**——每段音频一个独立子目录,日期写进 frontmatter(已在 Output Format 里写)而不是目录:

```
~/Desktop/即时学习/
├── <audio-slug>/               # 一音频一文件夹
│   ├── transcript.md            #   单 part 音频
│   ├── part<N>.md              #   多 part 音频 (part1.md / part2.md / ...)
│   ├── source.m4a              #   原始音频(可选,留作反查)
│   ├── source_part<N>.m4a      #   多 part 原始音频
│   └── merged/                 #   all.srt + all.txt(cleanup.sh 留,chunks 删)
├── archive/                    # 旧流程产物 + test scripts
└── <topic-folder>/             # 手动策展(Behave共读/视频学习/LOGS/播客/)
```

**`<audio-slug>` 命名**:
- **有主题**: 用主题或人名 (e.g., `Avery胡_优绩主义男孩的死亡`、`从失败到领悟_OPC复利循环`)
- **临时未取名**: 源文件名去扩展名,或 `<YYYYMMDD_HHMMSS>_<topic>` (e.g., `20260609_012544_4人对谈`)
- **避免**: `【转录】` 前缀(已废弃)、日期单层 folder(同日多音频会撞)

**为什么不用日期 folder**:
- 同日多音频不再挤一个目录
- Topic 浏览友好(按 slug 字母/拼音就分得开)
- `rm -rf <slug>/` 一键归档整段音频(含 source + merged)

完整约定 + 反例见 `~/Desktop/即时学习/README.md`。

## Cleanup Intermediate Files

**问题**：ASR pipeline 会产生 ~100-200MB 中间产物（chunks/*.wav 占大头，每 10min chunk 18MB），不清理会堆积。

**脚本**：`scripts/cleanup.sh`（独立可执行）

**默认行为**（最终 `.md` 写完后跑）：
- 删 `transcript_run_*/chunks/` 和 `transcript_<backend>_part<N>/chunks/`（.wav 大文件）
- 保留 `merged/all.txt` + `merged/all.srt`（小，每 part ~85KB，反查 / 重 cleanup 用）

**触发时机**：
- **推荐**：LLM cleanup pass 写完 `.md` 后**立即**跑
- **兜底**：7 天前的中间产物手动 `rm -rf`

**参数**：
- `--purge`：连 `merged/` 一起删（彻底）
- `--keep-wav`：保留 chunks/（覆盖默认）
- `--dry-run`：只打印不删

**示例**：
```bash
# 在音频所在目录跑
cd ~/Desktop/即时学习/2026-06-09
bash ~/.claude/skills/asr-transcript-refinement/scripts/cleanup.sh

# 看看会删什么
bash ~/.claude/skills/asr-transcript-refinement/scripts/cleanup.sh --dry-run

# 彻底删（包括 merged/）
bash ~/.claude/skills/asr-transcript-refinement/scripts/cleanup.sh --purge
```

## Backends

`pipeline.sh` 和 sub-agent 脚本**根据环境变量自动选 backend**：

| Backend | 触发条件 | 何时用 |
|---|---|---|
| **FunASR**（local） | `STEP_API_KEY` 未设 | 默认路径，0 成本，本地推理 |
| **Stepfun cloud** | `STEP_API_KEY` 已设 | 不方便本地装 venv / 想省时间 / 有 Step Plan 套餐时 |

```bash
# 默认：FunASR local
bash scripts/pipeline.sh input.mp3

# 切到 Stepfun cloud
export STEP_API_KEY=sk-...   # 或你的 Step Plan key
bash scripts/pipeline.sh input.mp3
```

**Stepfun 后端** (`transcribe_stepfun.py`) 用 SSE 流式 endpoint（`/v1/audio/asr/sse`），单 chunk 1-2 分钟音频实测 3-4 秒返回。价格 `stepaudio-2.5-asr` **0.15 元/小时**（5h 周配额），无 setup 成本。**只缺说话人分离**——如果需要 diarization，回退 FunASR（带 `cam++` 模型）。

**Webhook-like 注意事项**：Stepfun 不支持自定义说话人识别，TXT 里会写 `Speaker 0`（merge.py 兼容 FunASR 格式），下游 LLM cleanup 看到单一 speaker 自然合并。

## Setup (One-time)

```bash
bash scripts/setup.sh   # 创建 .venv-funasr + 装 torch/funasr/modelscope + 预下载模型
source .venv-funasr/bin/activate   # 每次新 shell 都要 source
```

## Common Mistakes

| 错误 | 修复 |
|------|------|
| 用 sherpa-onnx int8 替代 FunASR FP | 不要——int8 牺牲精度，「次等」就是指这个 |
| 手动逐个 chunk 转写不并行 | >10min 必并行，否则 1hr 要 1hr 跑完 |
| 跳过 LLM cleanup pass 直接用 FunASR 原始输出 | ITN 只做了基础规范化，专有名词/口语化错误还要 LLM 修 |
| LLM 过度"补完整" | 硬规则：转录稿不是文章，别 fabricate |
| 用同一 agent 又是 producer 又是 reviewer | Producer-Verifier 分离原则 |
| 没跑 verify.sh | 已知坏模式会漏掉（timestamps 残留 / N 準 / 协修） |

## Apple Silicon 性能说明

**官方无 Apple Silicon 专用版本**。当前 M 系列 Mac 上的实际表现：

| 硬件 | 实际 RTF | 备注 |
|------|---------|------|
| H100 GPU（数据中心） | 170x | 文章 benchmark 数字 |
| 8 核 CPU 服务器 | 17x | 文章 CPU 数字 |
| Apple M2 + MPS | **8.6x** | **我们实测**（含 VAD + 说话人） |

**M2 上 8.6x 比官方 CPU 数字（17x）略低**，可能原因：
- MPS 不是 ANE，部分 op 慢
- cam++ 说话人模型拖慢
- M2 vs 服务器 CPU 单核主频差距

如果追求 Mac 极限速度，可以走 sherpa-onnx + Core ML/ANE 路径（用 int8 量化），但牺牲精度——一般不值得。**当前默认 FunASR FP + MPS 是质量最优解**。

社区目前**没有**SenseVoice 的 MLX / Core ML 转换 PR，短期内不会有 Apple Silicon 专用加速。

## Real-World Impact

### Test case 1: 1m13s 小红书短视频 (2026-06-11)
- 文件：`(一个小号)邪修开发agent智能体...mp3`
- ASR：FunASR SenseVoice-Small FP + MPS
- 转写耗时：10.7s（RTF 0.116, 8.6x 实时）
- 模型加载：70.4s（首次）
- LLM cleanup：~30s
- 输出：`~/Desktop/即时学习/邪修开发Agent智能体/transcript.md`
- 质量：whisper base 错 4 处的专有名词（"skill的调用"/"上下文压缩"/"skill的文档"/"执行任务时"），FunASR 全对
- "G-E Memory" 这个点需要人工确认（FunASR 给 "记忆 Memory"）

### Test case 2: BV1AiEF6WEFJ 3h11m 课程 (v1 旧 workflow)
- 10 段
- 6 sub-agents（3 producer + 3 reviewer）
- 18 上下文确认 + 6 批改
- 1736 段，最终 grep 残留 = 0
- 这是 rigorous 模式的典型用例

### Test case 3: Stepfun cloud backend (2026-06-12)
- 文件：`(杨阿怡)烂梗分享` 1.4MB / 1m29s
- Backend：`stepaudio-2.5-asr`（Step Plan 订阅）
- 切分：1 chunk（<10min 不切）
- 转写耗时：3.7s（含 SSE 整流）
- 输出 28 段 SRT，ITN 正常，标点干净
- `merge.py` 兼容性 OK（输出一致）
- **对比 FunASR**：精度肉眼相当，速度快 2-3x（无模型加载），价格 ~0.005 元
