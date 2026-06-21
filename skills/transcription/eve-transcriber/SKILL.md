# EVE Transcriber - 本地语音转文字技能

> **版本**: v1.1.0 | **评估**: 100% Pass

## 简介

使用 Qwen3-ASR-0.6B 模型进行本地语音转文字，支持音频文件和 URL 输入。**唯一转录方案**，无需 API key，完全本地运行。

## 触发词

- "转录这个音频"
- "用千问转录"
- "转录这个链接"
- "帮我转录"
- "语音转文字"
- "把这个视频转成文字"

## 核心功能

1. **本地音频转录**: 支持 MP3, WAV, FLAC, M4A, MP4 等格式
2. **URL 音频下载**: 支持 B站、播客、视频链接自动下载
3. **自动分段**: >3分钟音频自动分段转录（解决模型输出截断问题）
4. **模型复用**: 长音频分段时模型只加载一次，大幅提升速度
5. **Markdown 输出**: 自动生成带元信息的转录文档

## 使用方式

```bash
# 转录本地音频
~/.claude/skills/eve-transcriber/scripts/transcribe.sh /path/to/audio.mp3

# 转录 B站视频
~/.claude/skills/eve-transcriber/scripts/transcribe.sh "https://www.bilibili.com/video/BVxxx"

# 指定输出目录
~/.claude/skills/eve-transcriber/scripts/transcribe.sh /path/to/audio.mp3 ~/Desktop/输出目录

# 转录播客 URL
~/.claude/skills/eve-transcriber/scripts/transcribe.sh "https://example.com/podcast.m4a"
```

## 技术细节

| 配置 | 值 |
|------|-----|
| 模型 | Qwen/Qwen3-ASR-0.6B |
| 设备 | CPU |
| 分段策略 | >3分钟自动分段，每段90秒 |
| 模型加载 | 分段转录时模型只加载一次 |
| 输出格式 | Markdown |
| 输出位置 | `~/Desktop/即时学习/` |

## 依赖项

- `ffmpeg`: 音频格式转换
- `yt-dlp`: 视频/音频下载
- `qwen-asr`: 千问 ASR 模型 (通过 eve 项目 venv)
- `eve/.venv`: Python 虚拟环境

## 注意事项

1. **长音频**: >3分钟自动分段，解决模型输出截断问题
2. **完全本地**: 无需 API key，保护隐私
3. **临时文件**: 脚本使用 `/tmp/eve_transcribe_$$` 存储临时文件，退出时自动清理
