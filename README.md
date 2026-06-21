<div align="center">

# 🧰 yishu-skills

#### 奕枢的公开 Claude Code skills 库

[![License](https://img.shields.io/badge/License-MIT-3B82F6?style=for-the-badge)](./LICENSE)
[![Skills](https://img.shields.io/badge/Skills-2-10B981?style=for-the-badge)](#-skills)
[![Platform](https://img.shields.io/badge/Claude_Code-Skill-8B5CF6?style=for-the-badge)](#-关于)

</div>

我自己每天在用、踩过坑验证过好用的 Claude Code skills，挑能公开的放在这里。每个 skill 都自包含文档 + 脚本，clone 下来按 `bash scripts/setup.sh` 就能跑。

> 2026-06 合并了 [agentic-assets](https://github.com/yishu-ziyu/agentic-assets) 的全部内容至此，后者保留为归档仓库。

---

## 📋 目录

| 名字 | 一句话 | 文档 |
|---|---|---|
| 🎙️ [**asr-transcript-refinement**](#-skills) | 音频 → 干净文稿（双模式 speed-first / rigorous） | [SKILL.md](./skills/asr-transcript-refinement/SKILL.md) · [README](./skills/asr-transcript-refinement/README.md) |
| 🎙️ [**transcription/eve-transcriber**](#-skills) | Qwen3-ASR 本地语音转文字（历史版） | [SKILL.md](./skills/transcription/eve-transcriber/SKILL.md) |


| 📝 [**academic-peer-review-workflow**](./skills/academic-peer-review-workflow) | 多轮审稿流程管理：从投稿到录用的全流程导航 | [SKILL.md](./skills/academic-peer-review-workflow/SKILL.md) |
| 📝 [**academic-reference-management**](./skills/academic-reference-management) | 参考文献选择、评估与格式化 | [SKILL.md](./skills/academic-reference-management/SKILL.md) |
| 📝 [**academic-manuscript-revision**](./skills/academic-manuscript-revision) | 系统化论文修订方法论（冷却法、诵读法、求教法） | [SKILL.md](./skills/academic-manuscript-revision/SKILL.md) |
| 📝 [**academic-paper-revision**](./skills/academic-paper-revision) | 五字法系统性论文修订框架 | [SKILL.md](./skills/academic-paper-revision/SKILL.md) |
| 📝 [**gbt7714-citation-standards**](./skills/gbt7714-citation-standards) | GB/T 7714-2015 引用格式标准 | [SKILL.md](./skills/gbt7714-citation-standards/SKILL.md) |

---

## 📦 安装

```
帮我安装这个 skill：https://github.com/yishu-ziyu/yishu-skills/tree/main/<skill-name>
```

把 `<skill-name>` 换成上面目录里的名字。装完后**首次使用**跑一次 setup：

```bash
cd ~/.claude/skills/<skill-name> && bash scripts/setup.sh
```

---

## ✨ Skills

<a id="-skills"></a>

<table><tr><td>

### 🎙️ asr-transcript-refinement

> _"播客太长听不完？先转成文稿再说。"_

把任何长度的音频（**播客 / 视频音轨 / 会议录音**）转成干净的**段落形式**中文文稿。区别于普通转写工具：

- **不只是 ASR**——含 LLM cleanup pass，删时间戳、合并段落、修正专有名词
- **速度快**——M2 Mac 实测 8.6x 实时（含 VAD + 说话人分离）
- **长音频友好**——>10 分钟自动 ffmpeg 切分 + sub-agent 并行
- **模型对**——用 FunASR 官方全精度 SenseVoice-Small，不用 sherpa-onnx int8

**两种模式**：

| 维度 | Speed-first（默认） | Rigorous（opt-in） |
|------|--------------------|--------------------|
| 1 小时音频耗时 | ~15 min（M2） | ~60-90 min |
| 质量 | 90% | 99% |
| 适用场景 | 播客 / 视频 / 日常 | 法律 / 医疗 / 学术 / 出版 |

**怎么触发**（对 Claude Code 说）：

```
用 asr-transcript-refinement skill 帮我转写 ~/Downloads/xxx.mp3
```

或者直接说「转写这段音频」/「跑一下 asr 流程」。

**🌐 平台**：仅 Claude Code（用了 `~/.claude/skills/` 路径约定 + Agent 工具派发 sub-agent）。

→ [SKILL.md](./skills/asr-transcript-refinement/SKILL.md) 完整方法论

</td></tr></table>

---

## 🗂️ 其他内容

<a id="-other"></a>

### Frameworks

开发方法论框架，见 [frameworks/](./frameworks/) 目录：

| 框架 | 描述 |
|------|------|
| [meta-flywheel](./frameworks/meta-flywheel/SKILL.md) | 感知→决策→执行→沉淀→进化的自我增强系统 |
| [skill-eval-framework](./frameworks/skill-eval-framework.md) | Skill 评估方法 |
| [iteration-process](./frameworks/iteration-process.md) | 迭代流程 |

### Trading

股票研究工具（回测、可视化），见 [trading/stock-research/](./trading/stock-research/)。

### References

- [SKILL.md 编写指南](./references/skill-guide.md)
- [框架设计原则](./references/framework-principles.md)
- [发布流程](./references/release-process.md)

### LOGS

开发日志和复盘记录，见 [LOGS/](./LOGS/)。

### Playbooks

实战复盘和最佳实践，见 [playbooks/](./playbooks/)。

---

## 🛣️ 路线图

- [x] **asr-transcript-refinement** — 音频转写精修流水线
- [x] **eve-transcriber** — Qwen3-ASR 本地转录（历史版）
- [ ] TBD — 等攒到下一个值得公开的 skill 再加

---

## 🌟 关于

奕枢（yishu）| 把日常用 Claude Code 攒下来的 skill 挑能公开的放在这里。**目前不接 PR**—— fork 改造随意，bug 反馈走 [Issues](https://github.com/yishu-ziyu/yishu-skills/issues)。

---

<div align="center">

[MIT License](./LICENSE) · [GitHub](https://github.com/yishu-ziyu)

</div>
