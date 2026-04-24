# field_replay

`field_replay` is a practical race-ops DVR and review tool built around `ffmpeg`.

Its current sweet spot is:

- record one growing near-live `timeshift.ts` file while the event is happening
- watch that file in VLC a few seconds behind live so you can pause and rewind
- burn a wall-clock timestamp into the video by default
- run a local vision model against the session to log likely bib sightings or custom detections
- review saved evidence frames and jump back into video when something needs confirmation

This is no longer just an experiment. The current workflow is stable and usable for real review work, especially when the goal is answering questions like "when did bib 241 arrive?" or "when was the last time we saw bib 573?"

## Current Reality

What is working well right now:

- DVR-first recording with `timeshift.ts` and a finalized `archive.mkv`
- interactive setup and saved profiles
- timestamp overlay burned into the video
- near-live VLC playback with practical rewind behavior
- local Ollama vision support for bib detection and custom label prompts
- promoted evidence logs plus saved frame grabs
- `find-bib` and `review` for post-hoc lookup of bibs or custom labels

What to treat as current assumptions:

- use a real Linux machine with direct access to `/dev/video*`
- RTSP input support is now scaffolded, but still lightly tested compared with V4L2 capture
- VLC has been the most reliable player for the growing DVR file
- the vision workflow is useful as a second set of eyes, not as gospel
- saved frame review in `eog` is now a first-class workflow, not just debugging

## Suggested System Requirements

These are practical guesses based on current use and local benchmarking, not hard enforcement rules.

### DVR-Only

Good target for recording and near-live review without AI vision:

- 4 CPU cores
- 8 GB RAM
- SSD-backed storage
- a working Linux video capture path
- hardware H.264 encode if available, but software fallback is supported

### DVR + Vision Review

Good target for recording, VLC review, and live bib detection with the current default vision model:

- 4+ CPU cores
- 16 GB RAM
- NVIDIA GPU with about 8 GB VRAM
- SSD-backed storage
- local Ollama server

The current default vision model is `gemma4:e2b`. On this workstation it has been the best field-oriented balance of:

- fit on GPU
- latency
- small-bib usefulness

Larger or less efficient models can work, but they may spill onto CPU/RAM and become too slow for pleasant live use.

## Packages

On a Debian or Ubuntu style Linux system, start with:

```bash
sudo apt update
sudo apt install ffmpeg vlc v4l-utils alsa-utils
```

Useful extras:

```bash
sudo apt install eog mpv vainfo usbutils
```

What they are for:

- `ffmpeg`: recording, remuxing, probing, frame extraction, and frame annotation
- `vlc`: DVR-style playback of the growing `timeshift.ts`
- `v4l-utils`: inspecting video devices and formats
- `alsa-utils`: inspecting audio devices
- `eog`: quick review of saved evidence frames
- `mpv`: optional alternate player
- `vainfo`: checking video acceleration support
- `usbutils`: identifying USB capture hardware with `lsusb`

If you want the repo's `mpv` near-live shortcut too, install the bundled config with:

```bash
./field-replay install-mpv-shortcuts
```

That installs:

- `~/.config/mpv/input.conf`
- `~/.config/mpv/scripts/live_minus.lua`

The current binding is:

- `End`: jump to about 2 seconds behind the live edge

If you want live vision features, also install and run Ollama separately.

## Core Workflow

### 1. Check the environment

```bash
./field-replay doctor
```

### 2. Save a reusable recording setup

```bash
./field-replay setup
```

`setup` is the best place to save a profile for a USB capture dongle or webcam. It can probe devices and remember useful settings like:

- video device
- or an RTSP URL plus transport preference
- V4L2 input format such as `h264`, `mjpeg`, or `yuyv422`
- video size and framerate
- whether video should be re-encoded or passed through with `-c:v copy`
- audio input mode
- encoder choice
- storage destination

When Linux exposes persistent V4L2 aliases, the video chooser shows `/dev/v4l/by-id/*`
paths and saves that stable path instead of a plain `/dev/video*` node.

For RTSP sources, the initial support is aimed at:

- saving a source profile
- generating the right FFmpeg ingest command
- recording into the usual `timeshift.ts` and `archive.*` session layout

The current RTSP caveats are:

- setup does not auto-probe RTSP streams yet
- `doctor` only validates that an RTSP URL is configured, not that the stream is reachable
- embedded stream audio is supported as a simple on or off choice, but the workflow has been tested much more with V4L2 plus ALSA

### 3. Record

For a straight recording flow:

```bash
./field-replay record
```

For the common one-tab workflow:

```bash
./field-replay go
```

`go` keeps FFmpeg in the foreground so `Ctrl-C` still stops and archives cleanly, then launches the player in the background once the DVR file is live.

### 4. Watch the near-live DVR

```bash
./field-replay watch
```

If you do not pass a target, `watch` offers a recent-session picker. It defaults to VLC because VLC has been the most reliable player so far for this growing file.

### 5. Run live or offline vision review

Offline scan:

```bash
./field-replay vision-scan ~/recordings/run-20260408-181629 --max-samples 3
```

`vision-scan` uses the same compare-frame path as `vision-live`, so it can keep a
permanent background object from masking a newer arrival with the same class
label. Use `--no-compare-frames` if you want the older one-frame behavior.

Offline resolution sweep:

```bash
./field-replay vision-sweep ~/recordings/run-20260408-181629 --max-samples 12
```

Based on local sweeps against real race footage, `720p` is the current recommended minimum for reliable bib-reading. Lower rungs such as `640x360` can still work on easier frames, but they started missing or mutating bibs often enough that they should be treated as experimental.

Live follow:

```bash
./field-replay vision-live ~/recordings/run-20260408-181629
```

`vision-live` follows a growing session at a predictable fixed cadence:

- grab a frame a few seconds behind live at each cadence point
- ask the local model for bib guesses or custom detections
- promote only useful sightings
- print promoted sightings to stdout without per-sample chatter

By default, live vision samples every `10s`, compares each sampled frame with the
previous sampled frame, and does not let motion suppress model calls. This keeps
the normal rolling `timeshift.ts` recording unchanged while making live sampling
behavior easier to reason about during field work. The default terminal view is
intentionally calm: promoted sightings and errors are visible, while per-sample
latency, "saw nothing" messages, and motion-gate skip markers stay out of the
operator's way.

If you pick an existing saved vision profile interactively, `vision-live` now
asks whether you want to edit that profile before it starts. That edit flow is
where `Sample cadence` is set for the saved profile.

To change the cadence:

```bash
./field-replay vision-live ~/recordings/run-20260408-181629 \
  --sample-interval 5
```

For tuning or debugging, add `--verbose` to print the per-sample diagnostic
stream while still writing the normal evidence logs:

```bash
./field-replay vision-live ~/recordings/run-20260408-181629 --verbose
```

For custom detection prompts, describe what to look for and let `vision-live`
handle the comparison JSON. For general scene monitoring, ask for descriptive
labels like `white pickup right` or `person in red shirt` so a parked object
does not mask a different arrival:

```bash
./field-replay vision-live ~/recordings/run-20260408-181629 \
  --prompt 'Find clearly visible people, pets, and cars in the main scene.'
```

With frame comparison enabled, the first sample uses the normal one-frame prompt.
After that, each model call receives the previous sampled frame and the current
frame, asks whether each current detection is `new`, `moved`, `unchanged`, or
`unclear`, and suppresses detections marked `unchanged` after the first sighting.
For generic object monitoring, the prompt should use descriptive labels so a
static background vehicle does not monopolize a plain `car` bucket. The normal
repeat cooldown still applies as a fallback. Suppressed comparison decisions are
recorded in `vision-debug.jsonl`. Use `--no-compare-frames` to go back to the
older one-frame behavior.

Motion gating is still available as an explicit opt-in diagnostic or load-shedding path:

```bash
./field-replay vision-live ~/recordings/run-20260408-181629 \
  --motion-gate \
  --motion-size 160x90 \
  --motion-threshold 8 \
  --motion-min-changed-pct 1.5 \
  --motion-consecutive 2 \
  --motion-hold 4
```

When motion gating is enabled, it skips Ollama calls until the watched scene changes
enough to be interesting. If no motion zone is saved yet, `vision-live` runs full-frame
and prints a hint about tightening the zone later.

If you enable motion gating and want to watch only part of the scene, you can either
pass a zone directly:

```bash
./field-replay vision-live ~/recordings/run-20260408-181629 \
  --motion-gate \
  --motion-zone B3:D4
```

or ask for an interactive preview at startup:

```bash
./field-replay vision-live ~/recordings/run-20260408-181629 \
  --motion-gate \
  --motion-select-zone
```

The selector uses a labeled `4x4` grid over a real frame from the session. Enter one cell like `C3`, two corners like `B3 D4`, or `full` to watch the whole frame.

For a running session, the simplest operator path is the standalone zone editor:

```bash
./field-replay motion-zone
```

That command lets you pick the active recording session, shows a real preview frame with the grid overlay, and writes the new zone to the session's live runtime control so a running `vision-live` loop can pick it up without restarting.

For tuning motion sensitivity after a live test, use:

```bash
./field-replay motion-tune
```

That command can run a short tail calibration, open triggered or near-miss clips with a `2s` preroll, record `good` / `false-positive` / `missed` feedback, and suggest updated motion settings for the current vision profile.

For custom prompt experiments, the vision parser accepts classic one-frame
responses:

```json
{"detections":["person","car"]}
```

or

```json
{"labels":["person","pet","car"]}
```

The parser still accepts older bib responses with `{"bibs":[...]}`.
In live comparison mode, it also accepts comparison responses like:

```json
{"detections":[{"label":"person","status":"new"},{"label":"car","status":"unchanged"}]}
```

### 6. Look up and review a bib or custom label

```bash
./field-replay find-bib 241
./field-replay review 241
```

`review` is designed for repeated use inside one chosen session:

- browse saved full frames in `eog`
- jump to first or last sightings in VLC when useful
- print recent evidence lines
- use `review all` to browse the whole promoted frame collection for a session
- type another bib directly at the action prompt without restarting the command

### 7. Export a share-friendly copy

```bash
./field-replay export
```

`export` offers a recent-session picker, then lets you choose a simple MP4 preset with an estimated size before encoding.

## Session Layout

A typical session folder looks like:

- `timeshift.ts`: the growing DVR file while recording is live
- `archive.mkv`: finalized recording after stop
- `session.json`: session metadata
- `vision-live/` or `vision-scan/`: vision evidence and diagnostics when used

Vision output currently includes:

- `events.log`: human-readable promoted sightings, good for `tail -f`
- `events.jsonl`: promoted event records
- `vision-debug.jsonl`: raw model diagnostics, latency, promoted and suppressed detections
- `frames/`: promoted evidence frames only

When motion gating is enabled, `vision-debug.jsonl` also records the per-sample motion scores and whether the gate stayed closed or allowed a vision call.

Promoted frames are annotated with the detected labels along the bottom beside the timestamp strip so they are easier to review in `eog`.

By default, the same bib or generic detection bucket is only promoted once every 60 seconds. In compare mode, generic object labels also use their comparison status so a persistent background object does not block a different `new` or `moved` sighting with the same class label. Sampled frames still go through the model and appear in diagnostics, but only promoted sightings are kept in `frames/` and surfaced in the operator-facing event log.

## Vision Notes

Current vision behavior is intentionally conservative:

- default model: `gemma4:e2b`
- detection-task prompts wrapped into strict JSON requests
- fixed-cadence live sampling
- calm live terminal output by default, with per-sample diagnostics behind `--verbose`
- two-frame comparison by default for bibs and generic scene monitoring, with repeat unchanged detections suppressed after the first sighting
- bib-focused prompts use neutral placeholder examples instead of a concrete sample number, which reduces hallucinated reads when no bib is visible
- optional motion gate before model calls
- repeat cooldown for calmer logs
- promoted frames only, not every sampled frame

This makes the live terminal and saved frame folder much more useful during stressful group movement.

The vision commands are best treated as:

- a live detection tail
- a source of saved evidence frames
- a fast way to jump back into video

They are not a guarantee of correctness. Some bibs or custom detections will still be missed, partially read, or never promoted.

## Player Behavior

For practical use, the distinction is:

- `watch` is for DVR-style playback of the growing `timeshift.ts`
- `archive.mkv` is the finalized recording after stop

If you open the live DVR file in VLC, you can usually:

- let playback sit near live
- pause when a pack goes by
- drag backward through already-recorded video
- jump around while the recorder keeps appending to the same file

`mpv` is still available with `--player mpv`, but VLC has been the better fit for this workflow so far.

## Profiles, Defaults, and Fallbacks

Profiles are stored in `~/.config/field-replay/config.json` by default.

A profile currently remembers:

- video device
- video codec mode
- video input format
- audio enabled or disabled
- audio device
- probed audio input rate and channel count
- probed video size and framerate
- preferred encoder
- recordings directory

Useful current defaults:

- device: `/dev/video2`
- audio device: `hw:Capture,0`
- audio input: `48 kHz` stereo
- audio output: `32 kHz` mono AAC at `32k`
- audio gain: `+18 dB`
- timestamp source: `generated`
- video timestamp overlay: enabled by default
- framerate: `30`
- size: `1920x1080`
- encoder: `h264_nvenc`
- preset: `fast`
- archive format after stop: `mkv`

If `h264_nvenc` is unavailable, the tool falls back to another available encoder such as `libx264`.

For cameras that already expose H.264 on a dedicated V4L2 node, you can save a profile with:

- `--device /dev/video4`
- `--video-input-format h264`
- `--video-codec-mode copy`

That keeps the incoming H.264 bitstream and writes it straight into the rolling `timeshift.ts`, which can significantly reduce CPU load compared with decode-and-re-encode. The main tradeoff is that passthrough mode cannot burn the wall-clock timestamp overlay into the video.

When a V4L2 profile selects `--video-input-format h264`, the tool now defaults that profile to passthrough mode automatically.

## Useful Commands

```bash
./field-replay doctor
./field-replay setup
./field-replay go
./field-replay watch
./field-replay vision-live
./field-replay find-bib 241
./field-replay review 241
./field-replay export
```

A few common variations:

```bash
./field-replay go --player vlc
./field-replay record --profile portable-capture --no-interactive
./field-replay record --no-audio
./field-replay record --no-video-timestamp
./field-replay vision-live ~/recordings/run-20260408-181629
./field-replay vision-scan ~/recordings/run-20260408-181629 --max-samples 20
./field-replay vision-scan ~/recordings/run-20260408-181629 --scale-to 640x360 --max-samples 20
./field-replay vision-sweep ~/recordings/run-20260408-181629 --variant source --variant 1280x720 --variant 640x360 --variant 320x180
./field-replay watch --player mpv
./field-replay export --preset share-small
./field-replay export --timelapse 60
./field-replay export --timelapse 120 --timelapse-output-fps 60 --preset share-small
```

`export` can create either a normal-speed share copy or a timelapse. In interactive mode it asks for the export type, then offers common timelapse speeds and playback frame rates before showing the final `ffmpeg` command.

`vision-sweep` writes one scan directory per tested rung plus `summary.json` and `summary.txt` under `vision-scan-sweep/`. The first rung is treated as the reference baseline for comparison, so the default ladder starts with `source`. In the sweeps so far, `720p` matched source reliably, while `640x360` and below were more likely to drop or misread harder bibs.

## Resource Review

If you want to estimate minimum hardware needs on your own system, useful tools are:

```bash
ollama ps
nvidia-smi
pidstat -rudh 1
du -sh ~/recordings/run-*
```

`vision-debug.jsonl` is also useful because it records `elapsed_ms` for each sampled frame, which gives you a direct sense of whether live vision is keeping up comfortably or struggling.

## Roadmap

Future feature ideas and race-ops notes live in [ROADMAP.md](ROADMAP.md).
