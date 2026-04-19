## Project overview

`field_replay` is a DVR-first field review tool for race operations and similar workflows. It records a growing `timeshift.ts`, finalizes an `archive.mkv`, opens near-live playback in VLC/mpv, and can run local Ollama vision passes to log bib sightings or custom detections.

The repo is intentionally small:

- `field-replay`: the main executable Python CLI. Most behavior lives here.
- `README.md`: current operator workflow and command examples.
- `ROADMAP.md`: backlog and product direction. Treat it as ideas, not promises.
- `extras/mpv/input.conf` and `extras/mpv/scripts/live_minus.lua`: optional mpv shortcut support.
- `notes.txt`: local hardware notes, not product documentation.

## Development style

- Prefer focused edits in `field-replay`; there is not yet a package/module split.
- Keep the CLI practical and field-oriented. The priority is reliable recording, review, and recoverability under event pressure.
- Optimize real operator paths around saved user-defined profiles and simple subcommands with at most one or two interactive prompts. In field use, operators should not need to remember long command lines, flags, device names, encoder settings, or media paths.
- Preserve backwards-compatible command names, saved profile keys, session layout, and evidence log formats unless the user explicitly asks for a migration.
- Avoid broad refactors unless they clearly reduce risk. The single-file script is large, so small helper extraction inside the file is usually safer than structural churn.
- Keep output operator-readable. Many commands are used live in a terminal.
- Use ASCII for edits unless an existing file or user-facing requirement already calls for Unicode.

## Important runtime assumptions

- Primary platform is Linux with direct access to `/dev/video*`, ALSA devices, and local desktop players.
- External tools are core dependencies: `ffmpeg`, `ffprobe`, VLC/mpv/ffplay, `v4l2-ctl`, ALSA utilities, optional `eog`, optional Ollama.
- The default capture path is V4L2 plus ALSA. RTSP support exists, but is less field-tested.
- `h264_nvenc` is the preferred encoder when available; the tool falls back to other encoders such as `libx264`.
- V4L2 H.264 passthrough via `--video-codec-mode copy` is important for low-CPU capture, but cannot burn the timestamp overlay.
- Vision features are a second set of eyes, not authoritative timing or bib proof.

## Session and config data

- Saved profiles live in `~/.config/field-replay/config.json` by default.
- Recordings default to `~/recordings`.
- A normal session contains `timeshift.ts`, a finalized `archive.*`, and `session.json`.
- Vision output directories such as `vision-live/`, `vision-scan/`, and `vision-scan-sweep/` may contain:
  - `events.log`
  - `events.jsonl`
  - `vision-debug.jsonl`
  - promoted evidence frames under `frames/`
- Do not casually delete, rewrite, or normalize generated session artifacts. They may be real race evidence.

## Validation commands

There is no formal test suite yet. Use a layered validation strategy based on the change:

```bash
python3 -m py_compile field-replay
./field-replay --help
./field-replay doctor --no-audio
```

For command construction changes, prefer dry runs before touching hardware:

```bash
./field-replay record --no-interactive --dry-run --no-audio
./field-replay go --no-interactive --dry-run --no-audio
./field-replay export --dry-run --no-interactive <session-or-media>
./field-replay vision-scan --dry-run --no-interactive <session-or-media>
./field-replay vision-sweep --dry-run --no-interactive <session-or-media>
./field-replay review 241 --mode summary --no-interactive <session-dir>
```

Hardware-dependent commands may fail on machines without the expected capture devices, players, GPU encoder, or Ollama server. Report that clearly rather than treating it as a code failure.

## CLI implementation notes

- Parser wiring is near the bottom of `field-replay` in `build_parser()`.
- Recording command construction is centered on `build_ffmpeg_command()`, `build_video_filter()`, `build_audio_filter()`, and `run_record_command()`.
- Setup/profile behavior is centered on `command_setup()`, `profile_from_args()`, `apply_profile()`, and related prompt helpers.
- Session lookup and review are centered on `recent_sessions()`, `resolve_session_dir()`, `resolve_export_source()`, `command_find_bib()`, and `command_review_bib()`.
- Vision scan/live behavior is centered on `process_vision_frame()`, `run_offline_vision_scan()`, `command_vision_scan()`, `command_vision_sweep()`, and `command_vision_live()`.
- Motion-zone and tuning behavior is centered on `normalize_motion_zone_spec()`, `motion_zone_pixel_rect()`, `command_motion_zone()`, and `command_motion_tune()`.
- mpv installer behavior copies the bundled files from `extras/mpv`.

## Change safety

- When changing ffmpeg arguments, validate the generated command with `--dry-run` and think through both V4L2 and RTSP sources.
- When changing timestamps, remember that wall-clock overlays are deliberately burned in for review work, while passthrough mode cannot use video filters.
- When changing evidence logs, preserve JSONL append behavior and keep human-readable `events.log` useful for `tail -f`.
- When changing motion gating, keep full-frame behavior as a fallback when no zone is configured.
- When changing playback, remember VLC has been the most reliable default for growing DVR files even though mpv support exists.
- When changing install behavior, avoid overwriting user config without making the planned destination obvious. `install-mpv-shortcuts --dry-run` should remain useful.

## Documentation expectations

- Update `README.md` when a user-facing command, default, workflow, or session artifact changes.
- Update `ROADMAP.md` only for product-direction changes or when the user asks to revise the backlog.
- Keep examples runnable from the repo root using `./field-replay`.

## Reasoning and session fit advisory

When useful, end substantive responses with a brief fit advisory to help the user choose future Codex CLI settings.

Use this especially after debugging, code edits, reviews, planning, or multi-step investigation. Omit it for trivial confirmations, very short answers, or purely conversational replies.

Classify the work actually required:

- Light: simple command help, obvious bug, small edit, formatting, narrow explanation
- Moderate: multi-file edits, routine debugging, test fixes, config changes, moderate refactor
- Heavy: ambiguous root cause, risky production change, architecture decisions, deep debugging, broad refactor

Append at most two short lines:

Reasoning fit: best suited to light|medium|high|xhigh reasoning. Optional brief note.
Session fit: aligned|neutral|drift. If drift is clear, suggest starting a fresh session.

Use:
- aligned when the task builds on recent work
- neutral when prior context likely had little impact
- drift when recent context is unrelated and likely wasting tokens

Keep the advisory brief and secondary. Do not mention token policy unless directly relevant.
