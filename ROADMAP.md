# Roadmap

`field_replay` started as a practical DVR-first recorder for aid stations, finish lines, and other race-adjacent review workflows.

These notes are not commitments. They are the current product leanings and backlog for helping an operator answer questions like "what happened to bib 241?" quickly, calmly, and with recoverable evidence.

## Current Direction

- Keep the continuous DVR recording as the trusted backbone. AI, audio, motion, and future sensors should make review faster, not decide what gets preserved.
- Treat the Jetson Orin NX as the deployment truth. Desktop RTX development can accelerate prototyping, but field behavior must be practical and performant on the Orin NVIDIA stack.
- Converge on a small nontechnical operator workflow: configure camera/storage once, start capture plus automatic detection, and review evidence. Experimental detectors, prompts, thresholds, and tracker knobs are development surfaces, not product commands.
- Favor simple, predictable live behavior over clever trigger chains. A missed heuristic should not cause missed evidence.
- Treat detections as candidates until a human confirms them. Partial bib reads like `1`, `12`, or `23` can still be useful context before the full `123` is visible.
- Preserve raw detail in diagnostics while keeping the live operator view calm through cooldowns, grouping, and promoted evidence frames.
- Build toward a live evidence dashboard: recent promoted events, saved frames, and quick jumps into the near-live video.

## High-Value Next Steps

- Broad significant-subject pipeline: run a general detector through DeepStream/TensorRT, use NvDCF tracks, and promote directional transit rather than class-specific or pixel-change-only events.
- Transit evaluation set: label representative car, runner, street, and nuisance-motion footage so parked objects, milling people, swaying lines/vegetation, and real passers can be measured before productizing the path.
- Identifier stage: run tentative bib/number reading only on good promoted subject crops after transit selection is reliable.
- Unknown significant-motion lane: retain a stricter coherent-motion path for unusual targets the detector does not classify, such as moving lights in the sky.
- Live event dashboard: after the detector path is credible, show event-dense minute buckets that skip quiet minutes, so a 30-line screen can cover the last 30 active minutes or more.
- Candidate grouping: cluster nearby detections by minute and show related partials beside stronger candidates without rewriting the underlying event log.
- Reconciliation view: list bibs with first seen, last seen, hit count, sources, and saved frames so the operator can review possible in-station or one-hit runners during a lull.

## Evidence Sources

- Vision remains a second set of eyes. Promoted frames with detected labels are central because human review can quickly explain model mistakes.
- Audio should start with reliable activity markers, then add tentative speech-to-text hints for bib numbers and callsigns rather than full transcripts.
- Motion should be a hint, not a gate. Outdoors it is too finicky to decide whether the system is allowed to look.
- For Jetson transit detection, the operator goal is broad rather than race-class-specific: promote coherent subjects that enter, move meaningfully through the frame, and exit or continue onward. Parked objects, background texture, swaying lines or vegetation, and small local human motion should fall away through track displacement, directional consistency, duration, and transit scoring; detector classes such as person, pet, bicycle, vehicle, or aircraft should be implementation hints, not things the operator must normally choose.
- Race mode may bias attention and identifier-reading strategy (`general`, `running`, `cycling`, or `motor`), but it must not prevent recording or surfacing another significant passing subject.
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
- Treat Jetson Orin NX 16 GB as the preferred field hardware target. Optimize field workflows around saved profiles and NVIDIA acceleration without making the live operator remember backend details.
- Treat Roger's RTX 4060 Ti 8 GB workstation as the local development target for NVIDIA experiments. Use dGPU DeepStream/TensorRT/CUDA/NVDEC/NVENC there, then keep Jetson deployment paths separate where JetPack/L4T devices and plugins differ.
- Keep large workstation artifacts on `/mnt/storage`: recordings, training/evaluation clips, generated TensorRT engines when practical, and DeepStream experiment outputs.
- On Jetson Orin-class hardware, prefer NVIDIA decode/inference paths: NVDEC/VIC/GStreamer for dense motion candidate windows, then DeepStream/TensorRT detectors, trackers, and OCR over those windows.
- Keep CPU handoffs narrow. Full-resolution frames should stay in NVMM/GPU memory until a candidate crop, metadata record, or promoted evidence frame is actually needed.
- Current Orin experiment finding (2026-05-25): DeepStream 7.1 plus NvDCF produced native person/bicycle tracks on the marathon clip, but the stock `nvdcf-perf` profile produced no tracked objects for a 30-second fast-car sample even though TrafficCamNet emitted car boxes. Preserve the visible fallback while evaluating tracker settings and the broader detector; do not treat stock NvDCF configuration as field-ready yet.
- Current Orin deployment finding (2026-05-25): first TensorRT engine construction took several minutes, while subsequent execution with a serialized engine was faster than real time. Prepare deployable engines before live event use.
- On stronger future hardware, improve cadence, resolution, model count, and camera count without changing the basic evidence model.
- More advanced object tracking, OCR, or multi-camera correlation should feed the same timeline and evidence logs rather than becoming a separate workflow.

## Possible Command Ideas

- `field-replay tail`
- `field-replay events`
- `field-replay reconcile`
- `field-replay audio-live`
- `field-replay clip-at 00:27:54`
- `field-replay ingest-rfid`

## Suggested Implementation Order

1. Preserve the DVR-first recording and near-live review path. (DONE)
2. Use the installed Orin DeepStream/NvDCF path to evaluate tracked transit behavior on existing clips. (IN PROGRESS: native track consumption, transit scoring, and a failure-visible fallback are wired; fast-car tracker coverage remains unresolved.)
3. Replace narrow TrafficCamNet experimentation with a broad YOLO-class DeepStream/TensorRT detector suitable for race and general observation use.
4. Refine transit scoring against an evaluation set for purposeful passers versus parked, milling, and swaying nuisance motion.
5. Add a stricter unclassified coherent-motion lane for meaningful targets outside detector labels.
6. Attach identifier reading to selected high-quality track crops and measure false reads.
7. Fold proven automatic detection into a small operator workflow and prune or hide unsuccessful laboratory commands.
8. Add dashboard, grouping, and richer review only over the evidence pipeline that survives evaluation.
