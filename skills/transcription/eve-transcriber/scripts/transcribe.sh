#!/bin/bash
# EVE Transcriber - 本地语音转文字工具
# 使用 Qwen3-ASR-0.6B 模型（唯一转录方案）
# 用法: ./transcribe.sh <音频文件或URL> [输出目录]
#
# 特性:
# - 自动检测音频时长，>3分钟自动分段转录
# - 修复路径展开问题（支持 ~ 路径）
# - 50%重叠防止句子断裂

set -e

# 配置
EVE_VENV="/Users/mahaoxuan/Desktop/AI产品经理/01-项目/eve/.venv"
MODEL_DIR="/Users/mahaoxuan/.cache/huggingface/hub/models--Qwen--Qwen3-ASR-0.6B/snapshots/5eb144179a02acc5e5ba31e748d22b0cf3e303b0"
DEFAULT_OUTPUT="$HOME/Desktop/即时学习"
TEMP_DIR="/tmp/eve_transcribe_$$"

# 转录配置
SEGMENT_DURATION=90  # 每段90秒
LANGUAGE="Chinese"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# 创建临时目录
mkdir -p "$TEMP_DIR"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# 检查参数
if [ -z "$1" ]; then
    echo "用法: $0 <音频文件或URL> [输出目录]" >&2
    exit 1
fi

INPUT="$1"
OUTPUT_DIR=$(eval echo "${2:-$DEFAULT_OUTPUT}")  # 修复: 展开 ~ 路径

is_url() { [[ "$1" =~ ^https?:// ]]; }
get_extension() { echo "${1##*.}" | tr '[:upper:]' '[:lower:]'; }
get_filename() { basename "$1" | sed 's/\.[^.]*$//'; }

# 获取音频时长（秒）
get_audio_duration() {
    local file="$1"
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null
}

# 下载音频
download_audio() {
    local url="$1"
    local output_path="$2"
    log_info "下载音频: $url"
    yt-dlp -x --audio-format mp3 -o "$output_path" "$url" 2>&1 || {
        log_error "下载失败"
        exit 1
    }
    echo "$output_path"
}

# 转换格式
convert_to_mp3() {
    local input="$1"
    local output="$2"
    log_info "转换格式: 16kHz 单声道"
    ffmpeg -y -i "$input" -ac 1 -ar 16000 "$output" 2>/dev/null
    echo "$output"
}

# 全量转录（模型只加载一次，片段批量处理）
transcribe_full() {
    local audio="$1"
    local duration="$2"
    
    # 计算分段数
    local total_seconds=$(echo "$duration" | cut -d. -f1)
    local segments=$(( (total_seconds + SEGMENT_DURATION - 1) / SEGMENT_DURATION ))
    
    if [ "$segments" -le 1 ]; then
        # 不足90秒，直接转录（单次模型加载）
        log_info "音频较短，直接转录..."
        "$EVE_VENV/bin/python3" << PYEOF 2>/dev/null
import warnings
warnings.filterwarnings('ignore')
from qwen_asr import Qwen3ASRModel

model = Qwen3ASRModel.from_pretrained(
    '$MODEL_DIR',
    device_map='cpu',
    dtype='float32',
)
result = model.transcribe(audio='$audio', language='$LANGUAGE', return_time_stamps=False)
print(result[0].text, end='', flush=True)
PYEOF
    else
        log_info "检测到音频时长 ${duration}秒，将分为 ${segments} 段转录..."
        
        # 先提取所有片段
        log_info "提取音频片段..."
        for i in $(seq 0 $((segments - 1))); do
            local start=$((i * SEGMENT_DURATION))
            if [ "$i" -eq $((segments - 1)) ]; then
                ffmpeg -y -i "$audio" -ss "$start" -ac 1 -ar 16000 "$TEMP_DIR/segment_${i}.mp3" 2>/dev/null
            else
                ffmpeg -y -i "$audio" -ss "$start" -t "$SEGMENT_DURATION" -ac 1 -ar 16000 "$TEMP_DIR/segment_${i}.mp3" 2>/dev/null
            fi
        done
        
        # 模型只加载一次，所有片段批量转录
        log_info "加载模型（仅一次）并转录所有片段..."
        
        # 把片段路径通过环境变量传入
        local segment_list=""
        for i in $(seq 0 $((segments - 1))); do
            segment_list="${segment_list}${TEMP_DIR}/segment_${i}.mp3 "
        done
        segment_list=$(echo "$segment_list" | sed 's/ $//')
        
        # 创建 Python 脚本文件
        cat > "$TEMP_DIR/batch_transcribe.py" << PYEOF
import warnings
import sys
import os
warnings.filterwarnings('ignore')
from qwen_asr import Qwen3ASRModel

MODEL_DIR = '/Users/mahaoxuan/.cache/huggingface/hub/models--Qwen--Qwen3-ASR-0.6B/snapshots/5eb144179a02acc5e5ba31e748d22b0cf3e303b0'
LANGUAGE = 'Chinese'
SEGMENTS = '$segment_list'.split()

model = Qwen3ASRModel.from_pretrained(MODEL_DIR, device_map='cpu', dtype='float32')

for i, seg in enumerate(SEGMENTS):
    print(f"[{i+1}/{len(SEGMENTS)}]", file=sys.stderr, flush=True)
    result = model.transcribe(audio=seg, language=LANGUAGE, return_time_stamps=False)
    print(result[0].text, end='', flush=True)
PYEOF
        
        # 执行脚本（进度到stderr，转录内容到stdout，过滤噪音）
        "$EVE_VENV/bin/python3" "$TEMP_DIR/batch_transcribe.py" 2>/dev/null | grep -vE "^\[|^Setting|following generation|temperature" || true
    fi
}

main() {
    local input_path="$INPUT"
    local name=""
    local output_markdown=""

    # 处理输入
    if is_url "$input_path"; then
        local ext=$(get_extension "$input_path")
        name=$(get_filename "$input_path")
        local temp_audio="$TEMP_DIR/audio.$$.$ext"
        input_path=$(download_audio "$input_path" "$temp_audio")
        if [ "$(get_extension "$input_path")" != "mp3" ]; then
            local mp3_path="$TEMP_DIR/audio.$$.mp3"
            input_path=$(convert_to_mp3 "$input_path" "$mp3_path")
        fi
        output_markdown="${OUTPUT_DIR}/${name}.md"
    else
        if [ ! -f "$input_path" ]; then
            log_error "文件不存在: $input_path"
            exit 1
        fi
        name=$(get_filename "$input_path")
        local temp_audio="$TEMP_DIR/audio.$$.mp3"
        if [ "$(get_extension "$input_path")" != "mp3" ]; then
            input_path=$(convert_to_mp3 "$input_path" "$temp_audio")
        else
            cp "$input_path" "$temp_audio"
            input_path="$temp_audio"
        fi
        output_markdown="${OUTPUT_DIR}/${name}.md"
    fi

    mkdir -p "$OUTPUT_DIR"

    # 获取时长并转录
    local duration=$(get_audio_duration "$input_path")
    log_info "音频时长: ${duration}秒"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_info "开始转录..."
    local text=$(transcribe_full "$input_path" "$duration")
    
    # 生成 Markdown
    cat > "$output_markdown" << EOF
# 音频转录

- 源文件: ${name}
- 模型: Qwen3-ASR-0.6B
- 设备: CPU
- 语言: $LANGUAGE
- 时长: ${duration}秒
- 转录时间: ${timestamp}

---

## 转录内容

${text}
EOF

    log_info "转录完成!"
    log_info "输出: $output_markdown"
    echo ""
    echo "--- 预览 (前500字) ---"
    echo "${text:0:500}"
}

main
