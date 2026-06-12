# asr-transcript-refinement

> 音频 → 干净文稿的端到端流水线。**双模式**：speed-first（默认，~15 分钟转 1 小时音频） / rigorous（opt-in，~60-90 分钟换 100% 准确率）。

![mode](https://img.shields.io/badge/mode-speed--first%20%7C%20rigorous-blue)
![model](https://img.shields.io/badge/ASR-FunASR%20SenseVoice--Small%20FP-orange)
![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![license](https://img.shields.io/badge/license-MIT-green)

## 这是什么

把任何长度的音频（**播客 / 视频音轨 / 会议录音**）转成干净的**段落形式**中文文稿。区别于普通转写工具：

- **不只是 ASR**——含 LLM cleanup pass，删时间戳、合并段落、修正专有名词
- **速度快**——M2 Mac 上 8.6x 实时（含 VAD + 说话人分离）
- **长音频友好**——>10 分钟自动 ffmpeg 切分 + sub-agent 并行
- **模型对**——用 FunASR 官方全精度 SenseVoice-Small，不用 sherpa-onnx int8

## 速度 vs 质量

| 维度 | **Speed-first**（默认） | **Rigorous**（opt-in） |
|------|------------------------|----------------------|
| 1 小时音频总耗时 | ~15 min（M2） | ~60-90 min |
| 质量（LLM cleanup 后） | 90% | 99% |
| 适用场景 | 播客 / 视频 / 日常 | 法律 / 医疗 / 学术 / 出版 |

## 安装

需要：
- macOS 或 Linux
- Python 3.12（`brew install python@3.12`）
- ffmpeg（`brew install ffmpeg`）
- ~3 GB 磁盘空间

```bash
# 1. 复制 skill 到 Claude Code skills 目录
cp -r skills/asr-transcript-refinement ~/.claude/skills/

# 2. 首次使用：装 venv + 下载模型（5 分钟左右）
cd ~/.claude/skills/asr-transcript-refinement
bash scripts/setup.sh

# 3. 之后每次新 shell 都要激活
source ../.venv-funasr/bin/activate
```

## 使用

```bash
# 完整流水线（split + transcribe + merge）
bash scripts/pipeline.sh your_podcast.mp3 ./output_dir

# 或手动：先切分
bash scripts/split.sh your_podcast.mp3 ./chunks

# 派 sub-agent 并行转写每个 chunk
# （详见 SKILL.md 的 Sub-agent Dispatch Pattern）

# 合并
python scripts/merge.py ./chunks ./all.srt ./all.txt

# LLM cleanup（主线程跑，应用"100% 上下文确证"规则）
# ↓ 这个不是脚本，是 LLM 看到 SRT/TXT 后做的工作

# 最后 verify
bash scripts/verify.sh final_transcript.md
```

## 架构

```
音频文件（任意长度）
  │
  ├─ < 10min ──────────────────────────────┐
  │                                         │
  └─ ≥ 10min → ffmpeg 切 10min chunks ──┐   │
                                          │   │
                                          ▼   ▼
                       派 N 个 sub-agent 并行转写
                       （每个跑 transcribe_chunk.py）
                                          │
                                          ▼
                       LLM cleanup（主线程单 pass）
                       - 应用"100% 上下文确证"规则
                       - 删时间戳，合并段落
                       - 标注存疑点
                                          │
                                          ▼
                       verify.sh：grep 已知坏模式
                                          │
                                          ▼
                       ~/Desktop/即时学习/【转录】{标题}.md
```

## 性能（M2 Mac 实测）

| 硬件 | RTF | 备注 |
|------|-----|------|
| H100 GPU（数据中心） | 170x | 文章 benchmark 数字 |
| 8 核 CPU 服务器 | 17x | 文章 CPU 数字 |
| **Apple M2 + MPS** | **8.6x** | **我们实测**（含 VAD + 说话人） |

完整 benchmark 和 Apple Silicon 限制详见 [SKILL.md](./SKILL.md)。

## 为什么不用 sherpa-onnx？

`SKILL.md` 里有完整讨论。简短版：sherpa-onnx int8 量化版跑得快但牺牲精度，"次等"就是因为这个。FunASR 官方全精度在中文 CER 上显著更强。

## 路线图

- [x] Speed-first 模式
- [x] Rigorous 模式（opt-in）
- [x] FunASR 后端
- [ ] Whisper large-v3-turbo 后端（对比 benchmark）
- [ ] Apple Silicon MLX 加速（社区等官方 PR）

## 详细文档

[SKILL.md](./SKILL.md) — 完整方法论、prompt 模板、Producer-Reviewer 协议。

## License

MIT
