# Roadmap

`field_replay` started as a practical DVR-first recorder for aid stations, finish lines, and other race-adjacent review workflows.

These notes are not commitments. They are the current product leanings and backlog for helping an operator answer questions like "what happened to bib 241?" quickly, calmly, and with recoverable evidence.

## Current Direction

- Keep the continuous DVR recording as the trusted backbone. AI, audio, motion, and future sensors should make review faster, not decide what gets preserved.
- Favor simple, predictable live behavior over clever trigger chains. A missed heuristic should not cause missed evidence.
- Treat detections as candidates until a human confirms them. Partial bib reads like `1`, `12`, or `23` can still be useful context before the full `123` is visible.
- Preserve raw detail in diagnostics while keeping the live operator view calm through cooldowns, grouping, and promoted evidence frames.
- Build toward a live evidence dashboard: recent promoted events, saved frames, and quick jumps into the near-live video.

## High-Value Next Steps

- Live event dashboard: show event-dense minute buckets that skip quiet minutes, so a 30-line screen can cover the last 30 active minutes or more.
- Fixed-cadence live vision: make predictable sampling the default path, with motion or audio used only to increase priority or cadence rather than suppress scanning.
- Candidate grouping: cluster nearby detections by minute and show related partials beside stronger candidates without rewriting the underlying event log.
- Reconciliation view: list bibs with first seen, last seen, hit count, sources, and saved frames so the operator can review possible in-station or one-hit runners during a lull.
- VOX evidence lane: log speech or radio activity as jumpable events, even before reliable transcription exists.
- Audio hints: optionally extract bib-like numbers, race callsigns, and radio keywords from speech segments as tentative events.

## Evidence Sources

- Vision remains a second set of eyes. Promoted frames with detected labels are central because human review can quickly explain model mistakes.
- Audio should start with reliable activity markers, then add tentative speech-to-text hints for bib numbers and callsigns rather than full transcripts.
- Motion should be a hint, not a gate. Outdoors it is too finicky to decide whether the system is allowed to look.
- RFID ingest remains useful if a reader and tag-to-bib lookup table exist, but it should land in the same timeline rather than becoming a separate workflow.
- Manual marks can be useful for unusual events, but the normal operator path should not require duplicate logging inside `field-replay`.

## Review Ideas

- Minute-bucket tail: show active minutes only, with sources such as vision, audio, radio/VOX, RFID, and manual notes.
- Bib review summary: show exact hits plus nearby partial candidates from the same minute or activity cluster.
- Jump-to-review: open the player a few seconds before the first, last, or selected evidence event.
- Contact-sheet or frame-browser review: browse promoted frames for one bib, one minute bucket, or one activity cluster.
- Activity-only export: generate a derived clip or reel from event windows while keeping the full DVR recording intact.
- Verification states may be useful later, but they should not become required live workflow.

## Two-Camera Direction

- Treat cameras as independent evidence lanes with shared timing, not as a complex tracking system.
- Store camera/source labels on events and frames so review can jump to the same minute on another angle.
- Keep per-camera recording reliable first; merge or compare evidence after capture.

## Hardware Guidance

- On old laptops, prefer continuous DVR, fixed-cadence vision, cooldowns, promoted frames, and event-dense review.
- Use motion and VOX to prioritize extra samples, not to hide quiet-looking intervals entirely.
- On stronger future hardware, improve cadence, resolution, and camera count without changing the basic evidence model.
- More advanced object tracking, OCR, or multi-camera correlation can come later, after the operator dashboard is useful with humble hardware.

## Possible Command Ideas

- `field-replay tail`
- `field-replay events`
- `field-replay reconcile`
- `field-replay audio-live`
- `field-replay clip-at 00:27:54`
- `field-replay ingest-rfid`

## Suggested Implementation Order

1. Shift live vision toward fixed-cadence sampling, leaving motion as optional priority/acceleration.
2. Add a simple event-dense tail/dashboard over existing evidence logs.
3. Add minute-level candidate grouping and partial-bib context.
4. Add reconciliation summaries for first seen, last seen, hit count, sources, and frames.
5. Add VOX/radio activity logging as jumpable evidence.
6. Add tentative audio bib/callsign extraction.
7. Add multi-camera evidence labels and same-minute review jumps.
8. Add activity-only exports, contact sheets, and richer review flows.
