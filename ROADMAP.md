# Roadmap

This project started as a practical DVR-first recorder for aid stations, finish lines, and other race-adjacent review workflows.

These notes are not commitments. They are a backlog of ideas that seem useful in the field, especially when the goal is to answer questions like "what happened to bib 241?" quickly and with confidence.

## High-value next steps

- Session event log: write timestamped `events.jsonl` data beside each session so bib sightings, spoken callouts, manual notes, and later RFID reads all share one timeline.
- Manual marks and notes: fast operator shortcuts for `arrived`, `left aid`, `medical`, `unknown bib`, or free-text notes.
- Frame grabs per event: save a full frame for each logged detection so operators can verify without rewinding video.
- Clock overlay: stamp wall-clock time and session-relative time into video and frame grabs so review stays easy under stress.
- Bib lookup: support queries like `find-bib 241` that show all evidence for a runner, including first seen, last seen, source, and confidence when available.

## Live review ideas

- Live log tail: a TUI or text view that shows recent bib detections as they happen.
- Jump-to-review: selecting a bib opens the player a couple seconds before the sighting.
- Annotated review overlay: draw green bounding boxes around detected bibs during playback or clip export.
- Bottom-bar labels: list detected bibs near the timestamp area and draw pointer lines back to their bounding boxes for easier multi-runner review.
- Annotated evidence frames: export promoted stills with the timestamp strip plus detected bib numbers burned into the bottom row for quick `eog` review.
- Group clustering: treat nearby detections as one departure pack so volunteers can compare "what I wrote down" versus "what the system saw."
- Verification states: mark detections as `unreviewed`, `confirmed`, `rejected`, or `manual-only`.
- Contact-sheet style review: browse saved frame grabs for one bib or one group without opening full video.

## Detection and evidence sources

- AI vision sidecar: continue developing the model-paced Ollama loop that grabs one frame behind live, asks a local image-capable model like `gemma4:e2b` to return bib guesses as strict JSON, then grabs the next frame only after the model responds.
- Promotion controls: keep every sampled frame and raw response in diagnostics, but only promote first sightings or cooldown-expired repeats into the operator-facing event log and review frame folder.
- Vision prompt and preprocessing experiments: tune prompts, frame scaling, contrast, and region-of-interest sampling to improve small or low-contrast bib reads.
- Audio callouts: optional speech-to-text for bib numbers called out by volunteers or radio operators.
- RFID ingest: if a reader and tag-to-bib lookup table exist, log RFID detections into the same event timeline.
- Evidence correlation: merge nearby vision, audio, RFID, and manual entries into stronger combined evidence for one bib.
- Pacer handling: treat `PACER` bibs and related tags as useful, distinct events rather than noise.

## Busy aid station realities

- Motion is only a hint. Crew, visitors, radio operators, and pacers create movement that should not automatically become runner events.
- Prefer zone-based or text-based detection over pure motion-triggered logging.
- Keep crew noise suppressible in the review UI, while still allowing special events like `PACER` to stand out.
- Store uncertainty instead of hiding it. A tentative detection can still help during a welfare check or search decision.

## Low-spec hardware guidance

- Cheap enough to try early:
  timestamp overlay, manual event log, event frame grabs, simple TUI views.
- Probably fine with careful tuning:
  motion-gated frame sampling and model-paced vision scans.
- Potentially too heavy unless the machine is stronger:
  continuous speech-to-text and more advanced vision models.

The safest pattern on weak hardware is to keep recording reliable, then layer selective vision and review helpers on top.

## Possible command ideas

- `field-replay events`
- `field-replay tail`
- `field-replay find-bib 241`
- `field-replay clip-at 00:27:54`
- `field-replay review`
- `field-replay ingest-rfid`

## Suggested implementation order

1. Add a per-session event log format.
2. Add manual marks and notes.
3. Add clock overlay and frame grabs.
4. Add bib lookup and simple review tooling.
5. Tune vision detection on saved frames and live samples.
6. Add annotated vision review exports or playback overlays.
7. Add live TUI review flows.
8. Add optional audio and RFID correlation.
