# extract-audio Skill

> 从视频文件中提取音频并转换为 MP3

## 触发条件

用户需要：
- 从视频提取音频
- 把视频转成音频
- 获取视频的声音部分

## 使用方法

用户提供视频路径后，执行以下步骤：

### 步骤 1：检查 ffmpeg

```bash
command -v ffmpeg
```

如果未安装，提示用户运行：`brew install ffmpeg`

### 步骤 2：查找文件（如果用户未提供完整路径）

```bash
# 如果用户在下载文件夹
ls -la ~/Downloads/ | grep -i "<关键词>"

# 如果在其他位置，先 find 找到文件
find ~ -name "*.mp4" -o -name "*.mov" -o -name "*.avi" | grep -i "<关键词>"
```

### 步骤 3：执行转换

```bash
ffmpeg -i "<视频完整路径>" -vn -ar 44100 -ac 2 -ab 192k "<输出mp3路径>" -y
```

输出路径规则：
- 默认：与视频同目录，扩展名改为 `.mp3`
- 用户指定输出位置时，按用户要求执行

### 步骤 4：确认结果

```bash
ls -lh "<输出文件路径>"
```

## 脚本入口

本仓库自带脚本（历史来源：yishuscripts，2026-08 合并）：

```bash
bash skills/extract-audio/scripts/extract-audio "<视频路径>" [输出目录]
```

## 脚本参数说明

| 参数 | 说明 |
|------|------|
| `$1` | 视频文件完整路径（必填） |
| `$2` | 输出目录（可选，默认与视频同目录） |

## 转换参数

- 采样率：44100 Hz
- 声道：立体声
- 比特率：192 kbps
- 格式：MP3

---

*Skill 版本：1.1*
*创建日期：2026-04-23（2026-08-31 自 yishuscripts 迁入）*
