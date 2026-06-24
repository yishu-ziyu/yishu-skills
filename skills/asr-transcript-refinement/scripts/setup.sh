#!/bin/bash
# setup.sh — One-time setup for asr-transcript-refinement (FunASR backend)
# Creates .venv-funasr next to this skill, installs torch/funasr/modelscope, pre-downloads SenseVoice-Small
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/../.venv-funasr"
PYTHON_BIN="${PYTHON_BIN:-python3.12}"

# Fall back to python3.12 from Homebrew if available
if ! command -v "$PYTHON_BIN" &> /dev/null; then
  if [ -x "/opt/homebrew/opt/python@3.12/bin/python3.12" ]; then
    PYTHON_BIN="/opt/homebrew/opt/python@3.12/bin/python3.12"
  elif [ -x "/usr/local/opt/python@3.12/bin/python3.12" ]; then
    PYTHON_BIN="/usr/local/opt/python@3.12/bin/python3.12"
  else
    echo "❌ Python 3.12 not found. Install via: brew install python@3.12"
    echo "   Then re-run with: PYTHON_BIN=/path/to/python3.12 bash setup.sh"
    exit 1
  fi
fi

echo "Using Python: $PYTHON_BIN ($(${PYTHON_BIN} -V 2>&1))"

# Create venv
if [ ! -d "$VENV_DIR" ]; then
  echo "[1/4] Creating venv at $VENV_DIR ..."
  $PYTHON_BIN -m venv "$VENV_DIR"
else
  echo "[1/4] Reusing existing venv at $VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
python -V
pip install --upgrade pip wheel setuptools --quiet

# Install PyTorch (no CUDA on Mac, just CPU + MPS via torch)
echo "[2/4] Installing torch + torchaudio ..."
pip install torch torchaudio --quiet

# Install FunASR + ModelScope
echo "[3/4] Installing funasr + modelscope ..."
pip install funasr modelscope --quiet

# Pre-download SenseVoice-Small + VAD + speaker models
echo "[4/4] Pre-downloading SenseVoice-Small + fsmn-vad + cam++ ..."
python -c "
from funasr import AutoModel
print('Downloading SenseVoice-Small (iic/SenseVoiceSmall) ...')
m = AutoModel(model='iic/SenseVoiceSmall', vad_model='fsmn-vad', spk_model='cam++', device='cpu')
print('All models cached. Setup complete.')
print('Venv path:', '$VENV_DIR')
print('Activate with: source $VENV_DIR/bin/activate')
"
