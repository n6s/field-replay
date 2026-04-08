# Roadmap

This project started as a practical DVR-first recorder for aid stations, finish lines, and other race-adjacent review workflows.

These notes are not commitments. They are a backlog of ideas that seem useful in the field, especially when the goal is to answer questions like "what happened to bib 241?" quickly and with confidence.

## High-value next steps

- Session event log: write timestamped `events.jsonl` data beside each session so bib sightings, spoken callouts, manual notes, and later RFID reads all share one timeline.
- Manual marks and notes: fast operator shortcuts for `arrived`, `left aid`, `medical`, `unknown bib`, or free-text notes.
- Frame grabs per event: save a full frame and optional bib crop for each logged detection so operators can verify without rewinding video.
- Clock overlay: stamp wall-clock time and session-relative time into video and frame grabs so review stays easy under stress.
- Bib lookup: support queries like `find-bib 241` that show all evidence for a runner, including first seen, last seen, source, and confidence.

## Live review ideas

- Live log tail: a TUI or text view that shows recent bib detections as they happen.
- Jump-to-review: selecting a bib opens the player a couple seconds before the sighting.
- Group clustering: treat nearby detections as one departure pack so volunteers can compare "what I wrote down" versus "what the system saw."
- Verification states: mark detections as `unreviewed`, `confirmed`, `rejected`, or `manual-only`.
- Contact-sheet style review: browse saved frame grabs or crops for one bib or one group without opening full video.

## Detection and evidence sources

- OCR for bib numbers: likely most practical when run on sparse frame samples or cropped regions instead of every full-resolution frame.
- Audio callouts: optional speech-to-text for bib numbers called out by volunteers or radio operators.
- RFID ingest: if a reader and tag-to-bib lookup table exist, log RFID detections into the same event timeline.
- Evidence correlation: merge nearby OCR, audio, RFID, and manual entries into stronger combined evidence for one bib.
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
  motion-gated frame sampling, cropped OCR at low frame rates, post-session OCR passes.
- Potentially too heavy unless the machine is stronger:
  full-frame real-time OCR, continuous speech-to-text, more advanced vision models.

The safest pattern on weak hardware is to keep recording reliable, then layer selective OCR and review helpers on top.

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
5. Add sparse OCR on saved frames or cropped regions.
6. Add live TUI review flows.
7. Add optional audio and RFID correlation.
