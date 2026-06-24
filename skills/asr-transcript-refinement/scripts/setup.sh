#!/bin/bash
# setup.sh — One-time setup for asr-transcript-refinement (GGUF binary backend)
# Downloads Fun-ASR-Nano GGUF models + llama-funasr-nano binary — no Python venv needed.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="${SCRIPT_DIR}/.."
BIN_DIR="${SKILL_DIR}/.bin"
GGUF_DIR="${SKILL_DIR}/gguf"

# Check for HuggingFace CLI (hf or huggingface-cli)
if   command -v hf              >/dev/null 2>&1; then HF=hf
elif command -v huggingface-cli >/dev/null 2>&1; then HF=huggingface-cli
else echo "❌ Hugging Face CLI not found. Install: pip install -U huggingface_hub"; exit 1; fi

echo "[setup] Installing Fun-ASR-Nano GGUF models + binary..."

# Download GGUF models from HuggingFace (FunAudioLLM/Fun-ASR-Nano-GGUF)
mkdir -p "$GGUF_DIR"
echo "[1/3] Downloading Fun-ASR-Nano GGUF models (encoder + LLM + VAD)..."
"$HF" download FunAudioLLM/Fun-ASR-Nano-GGUF --include "*.gguf" --local-dir "$GGUF_DIR"
"$HF" download FunAudioLLM/fsmn-vad-GGUF --include "*.gguf" --local-dir "$GGUF_DIR"

# Download prebuilt macOS arm64 binary from GitHub Releases
mkdir -p "$BIN_DIR"
echo "[2/3] Downloading llama-funasr-nano binary..."
RELEASE_URL="https://github.com/FunAudioLLM/Fun-ASR/releases/latest/download/funasr-llamacpp-macos-arm64.tar.gz"
if command -v curl >/dev/null 2>&1; then
  curl -sL "$RELEASE_URL" -o /tmp/funasr-llamacpp.tar.gz
elif command -v wget >/dev/null 2>&1; then
  wget -q "$RELEASE_URL" -O /tmp/funasr-llamacpp.tar.gz
else
  echo "❌ Need curl or wget to download binary"; exit 1
fi
tar xzf /tmp/funasr-llamacpp.tar.gz -C "$BIN_DIR" llama-funasr-cli
rm /tmp/funasr-llamacpp.tar.gz
chmod +x "$BIN_DIR/llama-funasr-cli"

# Verify
echo "[3/3] Verifying..."
if [ -f "$GGUF_DIR/funasr-encoder-f16.gguf" ] && [ -f "$GGUF_DIR/qwen3-0.6b-q8_0.gguf" ] && [ -f "$BIN_DIR/llama-funasr-cli" ]; then
  echo "✅ Setup complete!"
  echo "   Binary: $BIN_DIR/llama-funasr-cli"
  echo "   Models: $GGUF_DIR/ (~1.2 GB total)"
  echo "   No Python venv needed — zero dependency at runtime."
else
  echo "❌ Setup incomplete. Check errors above."; exit 1
fi
