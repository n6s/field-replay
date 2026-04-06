# field_replay

Small helper for capture-card recording with `ffmpeg`.

The current design is DVR-first:

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

Start a recording:

```bash
./field-replay record
```

That creates a session folder like `~/recordings/run-20260406-154331/` with:

- `timeshift.ts` while recording is in progress
- `archive.mkv` after the recording stops
- `session.json`

In another terminal, open the current DVR feed:

```bash
./field-replay watch
```

`watch` defaults to VLC because it has been the most reliable player so far for this growing DVR file. `mpv` is still available with `--player mpv`, but the tool now forces software decode there because hardware decode was not behaving well on this workstation.

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
- GOP: `30`
- archive format after stop: `mkv`

## Useful flags

```bash
./field-replay record --device /dev/video3
./field-replay record --no-audio
./field-replay record --audio-gain-db 24
./field-replay record --audio-bitrate 48k --audio-channels 2 --audio-sample-rate 48000
./field-replay record --timestamp-source device --timestamps default
./field-replay record --video-bitrate 8M --maxrate 10M --bufsize 20M
./field-replay record --session-name finish-line-a
./field-replay watch
./field-replay watch --player mpv
./field-replay watch --player vlc
./field-replay watch --player ffplay
./field-replay watch --file-caching-ms 100
./field-replay record --dry-run
```

## Older sessions

Older sessions that were recorded with the HLS workflow are still supported for archive remuxing, and `watch` will fall back to `live.m3u8` if a session does not have `timeshift.ts`.
