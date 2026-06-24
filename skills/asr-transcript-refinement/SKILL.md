---
name: asr-transcript-refinement
description: Use when transcribing audio (podcast / video / meeting) into clean Chinese paragraph form. Default backend is Fun-ASR-Nano GGUF (local, free, no Python venv, built-in VAD). Optional Stepfun cloud `stepaudio-2.5-asr` (opt-in, 0.15 元/小时). Single 70/30 split = single-speaker/multi-speaker — skill supports both.
---

# ASR Transcript Pipeline

> **v4 (2026-06-24)** — Default backend = Fun-ASR-Nano GGUF. Stepfun cloud is opt-in backup. PyTorch FunASR path removed (2026-06-24).

## Overview

End-to-end audio → clean transcript pipeline. Default uses **Fun-ASR-Nano** (FunAudioLLM GGUF release, encoder f16 + Qwen3-0.6B Q8_0, ~1.2G weights, ~1s binary startup, **no Python venv**) running on Apple Metal. Built-in FSMN-VAD segments long audio inside the binary — no ffmpeg chunking needed.

**Why Nano over SenseVoice-Small**: 6/24 benchmark on 5m40s 单人播客 showed Nano 5x fewer errors (专有名词/数字残留/韩文乱码), costing 18s extra per 5m40s. Worth it.

**Optional cloud backend**: [Stepfun 阶跃星辰 `stepaudio-2.5-asr`](https://platform.stepfun.com) — 0.15 元/小时, fast (4-5s per 3min chunk). No built-in speaker diarization. Opt in via `STEP_ASR_BACKEND=stepfun`.

**Core principle**: 留口误比瞎猜准 — preserve speaker fragments rather than paraphrase. Only fix ASR errors with 100% contextual confidence.

## Quick Decision (LLM first turn)

**收到"转录这个音频"时不要直接跑命令，先问用户 2 个问题**：

| 决策 | 单选 | 推荐 backend |
|------|------|--------------|
| **1. 说话人数量？** | 单人（独白 / 单主播 / 视频音轨解说）<br>多人（对话 / 访谈 / 圆桌 / 多人播客）| 单人 → **Fun-ASR-Nano GGUF**（默认）<br>多人 → **Fun-ASR-Nano GGUF**（70/30 用 Nano, LLM cleanup 阶段分 Speaker） |
| **2. 时长？** | < 10min<br>≥ 10min | 不切分（GGUF 内置 VAD 处理）<br>仍然不切分（VAD 自动切） |

**默认推荐**（用户不想回答时）：**本地 Fun-ASR-Nano** —— 不限说话人，不切分，启动 1s。

**询问模板**（复制即用）：
> 转录前先问 1 个：
> 1. 录音是**单人**还是**多人**？决定 cleanup 阶段要不要标 Speaker（Nano 不区分说话人）。
>
> 不想答的话默认走本地 Nano。

## Backends

| Backend | 触发条件 | 何时用 | 速度 (5m40s 音频) |
|---------|----------|--------|---------------------|
| **Fun-ASR-Nano GGUF** (本地) | 默认；或 `STEP_ASR_BACKEND != stepfun` | 永远首选 — 0 成本，本地推理，无网络 | ~40s (RTF 8-9x) |
| **Stepfun cloud** | `STEP_ASR_BACKEND=stepfun` 显式 opt-in | 不想本地推理 / 临时大文件 / 验证对照 | ~5s for 3min chunk (RTF 30x) |

```bash
# 默认：本地 Nano
bash scripts/pipeline.sh input.wav

# 显式 opt-in Stepfun
STEP_ASR_BACKEND=stepfun bash scripts/pipeline.sh input.wav
```

**重要**：skill **不再根据 `STEP_API_KEY` 自动切 Stepfun** — 你总是有 `STEP_API_KEY`（其它用途），自动切会导致每次都误走云端。改用 `STEP_ASR_BACKEND=stepfun` 显式 opt-in。

## When to Use

- 任何长度的音频文件（播客 / 抖音 B站视频音轨 / 会议录音）
- 中文为主，Nano 也支持 50+ 语言
- 输出想要段落形式

**Don't use when:**

- 实时流式转写
- 已经有干净文稿
- 需要翻译（这是另一个 task）
- 单词汇量 / 字幕嵌入视频（直接 SRT 输出即可，但 Nano 的 SRT 是**伪时间戳**——按字符数等分估算）

## Speed-First Workflow

```
输入：单音频文件（任何长度）
  │
  ├─ 默认 backend = Nano ──────────────────────────────┐
  │                                                     │
  └─ STEP_ASR_BACKEND=stepfun ──┐                       │
                                  │                       │
                                  ▼                       ▼
                pipeline.sh 调 transcribe_funasr.py    3min 切分 + Stepfun SSE
                (内置 VAD, 不切分)                     + merge.py
                          │                             │
                          ▼                             ▼
                  source.srt (伪时间戳)              merged/all.srt (真时间戳)
                  source.txt (按句切段)               merged/all.txt
                          │                             │
                          └──────────┬──────────────────┘
                                     ▼
                          Main: LLM cleanup (单 pass)
                          - 删时间戳，合并为段落
                          - 标 [存疑:xxx] inline
                          - 多人音频分 Speaker
                                     │
                                     ▼
                          bash scripts/verify.sh transcript.md
                                     │
                                     ▼
                          ~/Desktop/即时学习/<slug>/transcript.md
                          (或 part1.md / part2.md / ... 多 part)
```

## Real Working Paths (2026-06-24 现状)

| 文件 | 路径 | 说明 |
|------|------|------|
| GGUF binary | `~/Downloads/项目与数据/agent_audio_funasr/llama-funasr-nano` | arm64 native, Apple Metal |
| GGUF model | `~/Downloads/项目与数据/agent_audio_funasr/nano-gguf/{funasr-encoder-f16.gguf, qwen3-0.6b-q8_0.gguf, fsmn-vad.gguf}` | ~1.2G total |
| Wrapper | `~/Downloads/项目与数据/agent_audio_funasr/transcribe_funasr.py` | 本 skill 的实际入口（v2 加 SRT 输出） |
| Skill scripts | `~/.claude/skills/asr-transcript-refinement/scripts/` | pipeline.sh / split.sh / merge.py / verify.sh / cleanup.sh / transcribe_stepfun.py |
| Output | `~/Desktop/即时学习/<slug>/` | 一音频一文件夹 |

**不要修改** wrapper 路径 — 它是用户 2026-06-22 自己装的位置。改 wrapper 路径会破坏链接。

## SRT 输出（重要约束）

`transcribe_funasr.py` 输出 SRT，但**时间戳是估算的**：

- llama-funasr-nano 二进制 stdout 只有合并后的纯文本（不暴露 VAD 每段时间戳）
- wrapper 按 `。！？!?` 切分文本，得到 N 个段
- 每段时间戳 = `字符数 / 总字符数 × 音频总时长`（proportional allocation）
- 最后一段 end 强制对齐音频总时长

**这是设计取舍**：方案 A（改 C++ 源码暴露时间戳）需要重编 1-2h；方案 C（伪时间戳）= 0 改动 binary，覆盖 99% 反查场景。

**何时不能用 SRT**：视频字幕嵌入（Final Cut / 剪映）需要真时间戳 — 走 Stepfun backend（输出真 SRT）或先 LLM cleanup 后手动对齐。

## Cleanup Pass (Main Thread)

LLM 拿到 `source.srt` + `source.txt` 后，单 pass 输出 `transcript.md`：

**规则**（沿用 v3）：
- 删 SRT 索引 + 时间戳，合并为段落
- 多人音频分 `**Speaker N:**` 加粗前缀
- `[存疑:xxx]` inline 标注不单列块
- H2 节标题 = 主题切分（不写"概述"/"首先/其次/最后"八股）
- `H1 = 文件名`（去掉"完整转录稿"后缀）

**Hygiene 自检**（cleanup pass 完成后跑）：
```bash
bash scripts/verify.sh transcript.md
```

## Output Format

YAML frontmatter + 简化段落结构：

```markdown
---
date: 2026-06-24
source: fishcookies.wav
duration: 5min40s
backend: Fun-ASR-Nano GGUF (encoder f16 + Qwen3-0.6B Q8_0)
speakers: 1 (single-speaker)
notes: 单人播客; [存疑:xxx] 表示 ASR 无法 100% 确证
---

# fishcookies

## 开场: 自我介绍

**Speaker 1:** [内容...]

## 第一种方式: 模板套用

**Speaker 1:** [内容...]
—— [追问]?
**Speaker 1:** [回应]
```

## Output Location

**走法 B: 一音频一文件夹** — 每段音频一个独立子目录,日期写进 frontmatter:

```
~/Desktop/即时学习/
├── <audio-slug>/               # 一音频一文件夹
│   ├── transcript.md            #   单 part 音频
│   ├── part<N>.md              #   多 part 音频
│   ├── source.m4a              #   原始音频(可选)
│   ├── source_part<N>.m4a      #   多 part 原始音频
│   └── merged/                 #   all.srt + all.txt (Stepfun backend)
├── archive/                    # 旧流程产物 + test scripts
└── <topic-folder>/             # 手动策展
```

**`<audio-slug>` 命名**:
- 有主题: 用主题或人名 (e.g., `Avery胡_优绩主义男孩的死亡`)
- 临时未取名: 源文件名去扩展名
- 避免: `【转录】` 前缀(已废弃)、日期单层 folder(同日多音频会撞)

完整约定 + 反例见 `~/Desktop/即时学习/README.md`。

## Cleanup Intermediate Files

**脚本**: `scripts/cleanup.sh`（独立可执行）

**默认行为**（最终 `.md` 写完后跑）：
- Nano backend: 删 `transcript_run_*/chunks/`（无 chunks，但保险起见也跑）
- Stepfun backend: 删 `transcript_run_*/chunks/*.wav`，保留 `merged/all.txt` + `merged/all.srt`

```bash
# 看看会删什么
bash scripts/cleanup.sh --dry-run

# 彻底删
bash scripts/cleanup.sh --purge
```

## Setup (One-time)

不需要 setup。`~/Downloads/项目与数据/agent_audio_funasr/` 已经在 2026-06-22 装好。如果二进制或 GGUF 文件丢失：

```bash
cd ~/Downloads/项目与数据/agent_audio_funasr/
# 重新拉 GGUF（1.2G）
bash download-funasr-model.sh nano
```

## Common Mistakes

| 错误 | 修复 |
|------|------|
| 用 `STEP_API_KEY` 切 Stepfun | 不要 — 用 `STEP_ASR_BACKEND=stepfun` 显式 opt-in |
| 期望 Nano SRT 有真时间戳 | 不会 — Nano stdout 只有合并文本，SRT 是按字符数等分估算 |
| 跑 skill 自带的 setup.sh | 不要 — 真实环境在 `~/Downloads/项目与数据/agent_audio_funasr/`,不是 skill 内的 venv |
| 让 Nano 区分说话人 | 它不会 — cleanup pass 时 LLM 自己分 Speaker N |
| 把多个 chunk 串行过 Nano | 没必要 — Nano 内置 VAD 一把梭哈,不用切分 |

## Real-World Impact

### Test case: 5m40s 单人播客 Fishcookies (2026-06-24)

- Backend: **Fun-ASR-Nano GGUF** (default)
- 启动: 1s (vs PyTorch SenseVoiceSmall 70s)
- 推理: 42.2s (RTF 8-9x) — 包含 VAD + 切句 + 写文件
- 输出: 106 段 (按 。！？切), 9.9KB SRT (伪时间戳, 总长 340.85s 对齐)
- 质量: vs SenseVoice-Small — 0 数字残留 (vs 10), 1 专名错 (vs 4), 0 韩文乱码 (vs 1 段)
- Cleanup pass: 1 LLM call, ~2-3 min
- **总耗时: ~5 min** (vs 旧 PyTorch 路径 ~54 min)

### Test case: 1m13s 小红书短视频 (2026-06-11, 旧 v3)
- Backend: PyTorch FunASR SenseVoiceSmall (v3 旧路径, 已弃)
- 启动: 70s + 推理 10.7s
- 已被 v4 GGUF 路径超越

## Migration from v3

如果你之前用 v3 skill (PyTorch FunASR + SenseVoiceSmall):

| 改动 | 做什么 |
|------|--------|
| ~~`.venv-funasr` 在 skill 内~~ | 已删 — 真实环境在 `~/Downloads/项目与数据/agent_audio_funasr/` |
| ~~`transcribe_chunk.py` (PyTorch)~~ | 已删 — 改用 `transcribe_funasr.py` (GGUF wrapper) |
| ~~`transcribe_large.py` (PyTorch Large)~~ | 不存在, 跳过 |
| ~~`STEP_API_KEY` 自动切 Stepfun~~ | 改 `STEP_ASR_BACKEND=stepfun` 显式 |
| ~~setup.sh 装 venv~~ | 跳过 — 真实环境已装好 |
| ffmpeg 切 10min chunks | 不需要 — GGUF 内置 VAD |

## Scripts

| 脚本 | 用途 | 何时跑 |
|------|------|--------|
| `scripts/pipeline.sh` | 一键跑完 Nano (或 Stepfun) 转写 | 主线程, 转写前 |
| `scripts/transcribe_stepfun.py` | Stepfun cloud per-chunk | `STEP_ASR_BACKEND=stepfun` 时 sub-agent 跑 |
| `scripts/split.sh` | ffmpeg 切 3min chunks (Stepfun only) | Stepfun backend 内部用 |
| `scripts/merge.py` | 合并 SRT + TXT (按时间戳) | Stepfun backend 内部用 |
| `scripts/verify.sh` | grep 已知坏模式 + 时间戳残留 | Main: cleanup pass 之后 |
| `scripts/cleanup.sh` | 删 ASR 中间产物 | 最终 `.md` 写完后 |
