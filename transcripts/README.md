# Local Whisper Transcripts

This folder contains a local Whisper setup for transcribing MP4 files.

## Transcribe One MP4

```bash
./transcripts/transcribe.sh "/path/to/video.mp4"
```

## Transcribe A Folder Of MP4s

```bash
./transcripts/transcribe.sh "/path/to/folder"
```

By default, transcripts are written to:

```bash
transcripts/output
```

The default model is `medium`, and the default output format is `all`, which creates formats like `.txt`, `.srt`, `.vtt`, `.json`, and `.tsv`.

## Options

Use a faster model:

```bash
WHISPER_MODEL=small ./transcripts/transcribe.sh "/path/to/video.mp4"
```

Write only plain text:

```bash
WHISPER_FORMAT=txt ./transcripts/transcribe.sh "/path/to/video.mp4"
```

Write transcripts somewhere else:

```bash
WHISPER_OUTPUT_DIR="/path/to/output" ./transcripts/transcribe.sh "/path/to/video.mp4"
```
