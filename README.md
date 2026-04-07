# field_replay

Small helper for capture-card or USB-camera recording with `ffmpeg`.

The current design is DVR-first:

- pick a video source, audio source, and storage destination interactively
- remember useful setups as saved profiles without forcing you to type them
- record into one growing `timeshift.ts` file while the event is live
- include lightweight audio from the USB capture card when available
- open that file in a player like VLC so you can pause and scrub backward
- remux the finished recording into `archive.mkv` when you stop

This trades some latency for a much more practical "rewind the tape" workflow.

## Quick start

Run a dependency check:

```bash
./field-replay doctor
```

Create or update a reusable setup:

```bash
./field-replay setup
```

`setup` is the best place to save a profile for something portable like a USB capture dongle or webcam. It can probe the selected devices and remember a likely-good V4L2 input format like `mjpeg` or `yuyv422`, plus video mode, audio input mode, encoder, and storage destination.

Start a recording:

```bash
./field-replay record
```

If you already have a saved profile, `record` now offers a quick-start summary first. In the common case, pressing `Enter` immediately starts with the last-used setup, and `e` drops you back into the full editor if you need to change devices or storage.

By default, `record` now opens a simple interactive flow so you can choose:

- a saved profile, if you have one
- the current video device
- the current audio device or no audio
- the storage destination for the session

That creates a session folder like `~/recordings/run-20260406-154331/` with:

- `timeshift.ts` while recording is in progress
- `archive.mkv` after the recording stops
- `session.json`

In another terminal, open a DVR feed:

```bash
./field-replay watch
```

If you do not pass a target, `watch` offers an interactive picker of recent sessions across known recordings directories. It defaults to VLC because VLC has been the most reliable player so far for this growing DVR file. `mpv` is still available with `--player mpv`, but the tool now forces software decode there because hardware decode was not behaving well on this workstation.

The watch picker now labels each session with the target type it will open, such as `DVR timeshift` or `archive.mkv`, so it is clearer which entry is the still-growing live review file.

## Player behavior

For the workflow you described, the important distinction is:

- `watch` is for DVR-style playback of the growing `timeshift.ts`
- `archive.mkv` is the finalized recording after you stop

If you open the live DVR file in VLC, you can usually:

- let playback sit near live
- pause when a pack goes by
- drag backward through already-recorded video
- jump around the file much more naturally than with a short HLS playlist

If you want to compare players, `./field-replay watch --player mpv` is still available.

## Profiles and storage

Profiles are stored in `~/.config/field-replay/config.json` by default. Right now a profile remembers:

- video device
- video input format
- audio enabled/disabled
- audio device
- probed audio input rate and channel count
- probed video size and framerate
- preferred encoder for the current machine
- recordings directory

The tool also remembers your last chosen storage path and last watched session to keep the common path simple.

This makes it easier to use the same script on:

- a workstation with a large `/mnt/storage` partition
- a laptop or mini PC
- a Chromebook or Linux laptop writing to external storage

`record` also places a simple lock file under the recordings root so two recorder processes cannot grab the same video or audio device at the same time.

If a machine does not have `h264_nvenc`, `setup`, `record`, and `doctor` now fall back to another available encoder such as `libx264`.

For webcams and some USB capture devices, `setup` can also probe V4L2 input formats. That matters because the same device may behave very differently in raw `yuyv422` versus `mjpeg`.

For VLC playback, `watch` now disables VLC hardware decoding by default for this DVR file. That should make seeking around a growing `timeshift.ts` a bit less fragile.

## Defaults

The default capture settings are:

- device: `/dev/video2`
- audio device: `hw:Capture,0`
- audio input: `48 kHz` stereo
- audio output: `32 kHz` mono AAC at `32k`
- audio gain: `+18 dB`
- timestamp source: `generated`
- input queue: `512`
- framerate: `30`
- size: `1920x1080`
- encoder: `h264_nvenc`
- preset: `fast`
- GOP: about `1` second of video, based on the selected framerate
- archive format after stop: `mkv`

## Useful flags

```bash
./field-replay setup
./field-replay setup --video-input-format mjpeg
./field-replay setup --profile portable-capture --no-interactive --no-probe
./field-replay record --device /dev/video3
./field-replay record --video-input-format mjpeg
./field-replay record --no-audio
./field-replay record --profile portable-capture --no-interactive
./field-replay record --no-interactive
./field-replay record --audio-gain-db 24
./field-replay record --audio-bitrate 48k --audio-channels 2 --audio-sample-rate 48000
./field-replay record --timestamp-source device --timestamps default
./field-replay record --video-bitrate 8M --maxrate 10M --bufsize 20M
./field-replay record --session-name finish-line-a
./field-replay --recordings-dir /mnt/storage/field-replay record
./field-replay watch
./field-replay watch --no-interactive
./field-replay watch --player mpv
./field-replay watch --player vlc
./field-replay watch --player ffplay
./field-replay watch --file-caching-ms 100
./field-replay record --dry-run
./field-replay --config-file /tmp/field-replay-config.json record
```

## Older sessions

Older sessions that were recorded with the HLS workflow are still supported for archive remuxing, and `watch` will fall back to `live.m3u8` if a session does not have `timeshift.ts`.
