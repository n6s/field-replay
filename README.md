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

## Requirements

On a Debian or Ubuntu style Linux system, including Linux on a Chromebook, plan on these packages:

```bash
sudo apt update
sudo apt install ffmpeg vlc v4l-utils alsa-utils
```

Useful extras:

```bash
sudo apt install mpv vainfo usbutils
```

What they are for:

- `ffmpeg`: recording, remuxing, probing
- `vlc`: DVR-style playback
- `v4l-utils`: inspecting video devices and formats
- `alsa-utils`: inspecting audio devices
- `mpv`: optional alternate player
- `vainfo`: checking video acceleration support
- `usbutils`: identifying USB capture hardware with `lsusb`

Notes for Linux on a Chromebook:

- Hardware encoding may differ from your workstation, so `field-replay` should be allowed to fall back from `h264_nvenc` to another encoder like `libx264`.
- USB device forwarding into the Linux environment can matter just as much as package installation.
- Storage may be tighter, so using an external drive or a larger mounted path is often the right move for long events.
- In our testing with Crostini, a USB HDMI capture dongle did not appear in the Linux USB-sharing UI and did not create any `/dev/video*` device nodes. As of April 7, 2026, Google documents that cameras are not yet supported for Linux on Chromebook, so a capture dongle may simply be unavailable there.
- Practical takeaway: a Chromebook running Crostini is not a reliable target for USB capture-card recording right now. It may still be useful as a viewer, notes/logging machine, or remote terminal into a separate Linux recorder.

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

If you already have saved profiles, `record` now starts with a profile picker. In the common case, pressing `Enter` immediately starts the default profile, and `Manual / edit setup` drops you into the full editor if you need to change devices or storage.

By default, `record` now opens a simple interactive flow so you can choose:

- a saved profile, if you have one
- the current video device
- the current audio device or no audio
- the storage destination for the session

If you want a one-tab workflow, try:

```bash
./field-replay go
```

`go` uses the same setup/profile flow as `record`, keeps FFmpeg in the foreground so `Ctrl-C` still stops and archives cleanly, and launches the player in the background once the DVR file is live.

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

When you want a share-friendly copy after the event:

```bash
./field-replay export
```

`export` offers an interactive picker of recent sessions across known recordings directories, then lets you choose a simple MP4 share preset with an estimated file size before it runs.

When possible, `export` now prefers a hardware H.264 encoder that matches the original session and writes a small sidecar JSON file next to the MP4 so you can tell later how the share copy was produced.

## Vision Bib Detection

There is an experimental Ollama vision sidecar for bib detection. It runs independently against an existing or current session:

```bash
./field-replay vision-scan ~/recordings/run-20260408-181629 --max-samples 3
./field-replay vision-live ~/recordings/run-20260408-181629
./field-replay find-bib 241
./field-replay find-bib 241 ~/recordings/run-20260408-181629
./field-replay review-bib 241
```

`vision-live` follows a growing session in a model-paced loop: it grabs one frame from a few seconds behind live, waits for the local model response, then grabs the next available frame. `vision-scan` samples a saved session or media file for offline testing.

The vision commands default to the local Ollama model `gemma4:e2b`, ask for strict JSON bib guesses, and write these files under `vision-live/` or `vision-scan/`:

- `events.log`: human-readable lines that are easy to `tail -f`
- `events.jsonl`: promoted vision sightings with timestamps and saved frame paths
- `vision-debug.jsonl`: diagnostics showing the raw model response and `elapsed_ms` timing for each sampled frame
- `frames/`: saved full-frame grabs used as evidence

`review-bib` gives you a simple menu to jump into video a couple seconds before the last or best sighting, or browse the saved full-frame grabs in an image viewer.

## Player behavior

For the workflow you described, the important distinction is:

- `watch` is for DVR-style playback of the growing `timeshift.ts`
- `archive.mkv` is the finalized recording after you stop

If you open the live DVR file in VLC, you can usually:

- let playback sit near live
- pause when a pack goes by
- drag backward through already-recorded video
- jump around the file while the recorder keeps appending to the same DVR file

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
- video timestamp overlay: wall-clock burned in by default
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
./field-replay go
./field-replay go --player vlc
./field-replay record --device /dev/video3
./field-replay record --video-input-format mjpeg
./field-replay record --no-audio
./field-replay record --profile portable-capture --no-interactive
./field-replay record --no-interactive
./field-replay record --audio-gain-db 24
./field-replay record --audio-bitrate 48k --audio-channels 2 --audio-sample-rate 48000
./field-replay record --timestamp-source device --timestamps default
./field-replay record --no-video-timestamp
./field-replay record --video-bitrate 8M --maxrate 10M --bufsize 20M
./field-replay record --session-name finish-line-a
./field-replay --recordings-dir /mnt/storage/field-replay record
./field-replay watch
./field-replay watch --no-interactive
./field-replay watch --player mpv
./field-replay watch --player vlc
./field-replay watch --player ffplay
./field-replay watch --file-caching-ms 100
./field-replay export
./field-replay export --preset share-small
./field-replay export --dry-run
./field-replay record --dry-run
./field-replay --config-file /tmp/field-replay-config.json record
```

## Roadmap

Future feature ideas and race-ops notes live in [ROADMAP.md](ROADMAP.md).
