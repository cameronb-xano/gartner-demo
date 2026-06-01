#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHISPER_BIN="$SCRIPT_DIR/.venv/bin/whisper"

INPUT_PATH="${1:-}"
MODEL="${WHISPER_MODEL:-medium}"
OUTPUT_FORMAT="${WHISPER_FORMAT:-all}"
OUTPUT_DIR="${WHISPER_OUTPUT_DIR:-$SCRIPT_DIR/output}"

usage() {
  echo "Usage: $0 <video.mp4 | folder-with-mp4s>"
  echo
  echo "Optional environment variables:"
  echo "  WHISPER_MODEL=small|medium|large   Default: medium"
  echo "  WHISPER_FORMAT=txt|srt|vtt|json|all Default: all"
  echo "  WHISPER_OUTPUT_DIR=/path/to/output  Default: $SCRIPT_DIR/output"
}

if [[ -z "$INPUT_PATH" ]]; then
  usage
  exit 1
fi

if [[ ! -x "$WHISPER_BIN" ]]; then
  echo "Whisper is not installed at $WHISPER_BIN."
  echo "Run: python3 -m venv transcripts/.venv && transcripts/.venv/bin/python -m pip install -U pip openai-whisper"
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is not installed. Run: brew install ffmpeg"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

files=()
if [[ -d "$INPUT_PATH" ]]; then
  shopt -s nullglob
  files=("$INPUT_PATH"/*.mp4 "$INPUT_PATH"/*.MP4)
  shopt -u nullglob
elif [[ -f "$INPUT_PATH" ]]; then
  files=("$INPUT_PATH")
else
  echo "Input path does not exist: $INPUT_PATH"
  exit 1
fi

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "No MP4 files found in: $INPUT_PATH"
  exit 1
fi

for file in "${files[@]}"; do
  echo "Transcribing: $file"
  "$WHISPER_BIN" "$file" \
    --model "$MODEL" \
    --output_format "$OUTPUT_FORMAT" \
    --output_dir "$OUTPUT_DIR"
done

echo "Done. Transcripts written to: $OUTPUT_DIR"
