# smokefire Fire, Smoke & Smoking Detection

## User Operation Manual

**Prepared by: Shenzhen Dudumiao Technology Co., Ltd.**  
**Document version: V1.0**  
**Applicable software version: 1.0.0**  
**Updated: 2026-08-03**

> smokefire assists operators in finding visible fire, smoke, and smoking behavior in video. Every alert requires prompt human verification and response. The system does not replace statutory fire protection, human patrols, emergency procedures, or on-site verification. False alerts and missed events are possible.

---

## Document information

| Item | Value |
|---|---|
| Document | smokefire User Operation Manual |
| Audience | Duty operators, site administrators, and event reviewers |
| Default URL | `http://127.0.0.1:8600` |
| Main pages | Live Wall, Event Center, Camera Management |
| Project | `https://github.com/newtv-ai/smokefire` |

## Contents

1. System overview
2. First use
3. Live Wall
4. Camera Management
5. Event Center
6. Alert response
7. False-positive feedback
8. Storage Management
9. Alert notifications
10. Daily operating routine
11. Frequently asked questions
12. Quick reference

---

## 1. System overview

The top navigation provides three principal pages:

| Page | Purpose | Typical user |
|---|---|---|
| Live Wall | View live images, runtime status, and recent alerts | Duty operator |
| Event Center | Filter, review, play, and process alerts | Operator and reviewer |
| Camera Management | Add, edit, disable, and tune cameras and webhooks | Administrator |

By default, the system samples one frame per second and requires four consecutive threshold-passing frames before creating an alert. It stores one second of evidence before and after the event. These are starting values only; validate them for each camera view and business requirement.

---

## 2. First use

### 2.1 Open the system

On the service host, open:

```text
http://127.0.0.1:8600
```

Use the site URL supplied by the implementer when remote access has been configured. The application has no built-in login screen; access scope is controlled by the deployment environment.

### 2.2 Recommended first-use sequence

1. Open Camera Management and add the first camera.
2. Wait for Starting or Reconnecting to change to Online.
3. Open Live Wall and confirm the image, name, and camera view.
4. Trigger a controlled alert using authorized test material.
5. Open Event Center and verify the snapshot, clip, time, and camera name.
6. Test both Confirmed and Mark False Positive.
7. If integrating a third-party platform, configure the webhook and perform an end-to-end delivery test.

---

## 3. Live Wall

The wall automatically lays out cameras for the browser window. Use Previous and Next when there are more cameras than one page can display.

### 3.1 Camera states

| State | Meaning | Recommended action |
|---|---|---|
| Online | AI detection and video processing are running | Continue normal patrol |
| Starting | The source and processing pipeline are initializing | Wait briefly |
| Reconnecting | The stream was interrupted and retry is in progress | Check network/RTSP if persistent |
| Recording warm-up | Video is available but the first closed recording segment is not ready | Wait for the first segment |
| Disabled | The camera is intentionally stopped | Enable it in Camera Management when needed |
| Error | The source or processing pipeline has failed | Record the message and contact an administrator |

### 3.2 Patrol focus

- Confirm the image updates continuously rather than showing a frozen frame.
- Check that the camera name and physical location match.
- Investigate persistent Reconnecting or Recording warm-up states.
- Review the newest alert card promptly and open Event Center for evidence.
- Do not treat an Online badge as proof that detection quality is acceptable; image quality and target size still matter.

---

## 4. Camera Management

### 4.1 Add a camera

1. Select Add Camera.
2. Enter a unique, recognizable name.
3. Enter the full RTSP URL supplied by the camera or NVR administrator.
4. Enable Fire/Smoke and/or Smoking detection as required.
5. Confirm the sampling rate and evidence recording window.
6. Save and wait for Online.
7. Verify the image in Live Wall.

Example RTSP URL:

```text
rtsp://user:password@192.168.1.20:554/stream1
```

### 4.2 Main fields

| Field | Purpose | Guidance |
|---|---|---|
| Name | Identifies the camera in pages and alerts | Include building/floor/area where useful |
| RTSP URL | Video source | Copy exactly; credentials are case-sensitive |
| Enabled | Starts or stops processing | Disable cameras under maintenance |
| Fire/Smoke | Enables the fire/smoke model | Use for relevant camera views |
| Smoking | Enables the smoking model | Use where people are large enough in frame |
| Detection FPS | Sampling frequency | Higher values increase compute and may change alert behavior |
| Pre/Post seconds | Evidence around an alert | Increasing them consumes more storage |
| Webhook | Per-camera notification target | Test real delivery after saving |

### 4.3 Edit, disable, and delete

- Edit changes the source or detection settings.
- Disable preserves configuration and history but stops processing.
- Delete removes the camera configuration; historical events remain in Event Center until separately deleted.
- Record a change ticket before editing production camera URLs, thresholds, or sampling policy.

### 4.4 Camera placement

Keep the target area unobstructed and avoid severe backlight, glare, and rapid camera shake. The relevant target must occupy enough pixels: a high-resolution stream does not help if a person, cigarette, flame, or smoke plume is still very small in the scene.

### 4.5 Capacity notices

When the interface reports insufficient capacity, do not simply add more cameras. Reduce stream resolution/bitrate or detection rate only after a representative replay test, or move the workload to a more capable host.

---

## 5. Event Center

### 5.1 Review and filter

Filter by time, camera, capability, label, or handling status. Each event normally shows:

- camera and event time;
- fire, smoke, or smoking label;
- confidence from the triggering evidence;
- clean and annotated snapshots;
- evidence clip when available;
- notification and handling state.

### 5.2 Open details and playback

Open an event to compare the clean image with the annotated image and play the clip. Do not decide from the box alone. Check whether the visible object, motion, and surrounding context match a real event.

### 5.3 Handling actions

| Action | Use when | Result |
|---|---|---|
| Pending | Evidence has not yet been reviewed | Keeps the event in the pending queue |
| Confirmed | A person verifies a real fire, smoke, or smoking event | Records the handling decision |
| Mark False Positive | The model detected a non-target scene | Archives feedback for later review |

Only authorized reviewers should make final decisions. If evidence is unclear, follow the site's escalation procedure rather than guessing.

### 5.4 Heartbeat/recovery notices

The notification channel can send a heartbeat or recovery summary after interruptions. A heartbeat is not a new detection event. Use its counters and timestamps to understand whether notifications were delayed or recovered.

---

## 6. Alert response

Use the site's emergency procedure first. A recommended operational sequence is:

1. Open the event and verify the live view and evidence clip.
2. Identify the camera, location, time, and target class.
3. For suspected fire or smoke, immediately follow the approved fire response and escalation process.
4. For smoking, follow the site's safety and conduct procedure.
5. Do not delay a real emergency while adjusting software or replaying clips.
6. After the situation is controlled, mark the event and record the response outcome.

The software must never be the only path for reporting a dangerous condition.

---

## 7. False-positive feedback

### 7.1 Mark a false positive

Open the event, select Mark False Positive, choose or enter a reason, and confirm. Useful reasons describe what the model confused, for example steam, fog, reflection, welding, eating, or a handheld object.

### 7.2 Download feedback

Authorized administrators can export a feedback package for model analysis. Review the package before transferring it because images, clips, camera names, URLs, or site details may be sensitive.

### 7.3 Clear feedback

Clearing feedback is irreversible from the application. Export and verify the required package first, and follow the site's retention and approval process.

---

## 8. Storage Management

Storage Management displays evidence usage and allows deletion by time range.

### 8.1 Delete by time range

1. Confirm the required evidence has been backed up.
2. Select the exact time range.
3. Review the expected number of affected events.
4. Confirm deletion.
5. Recheck disk usage and a sample of retained events.

Deleting events removes associated evidence and should follow the site's authorization and retention policy.

### 8.2 High-water status

When disk use reaches the high-water threshold, recording or event commits may be restricted to protect service stability. Back up first, then delete approved old evidence or expand the data disk. Do not manually remove random files from the Docker volume.

---

## 9. Alert notifications

### 9.1 Configure a webhook

An administrator can set a global webhook during deployment or a per-camera webhook in Camera Management. Save the configuration and perform a controlled real delivery test.

### 9.2 Notification points

- The receiver should return a success response promptly.
- Receiver-side deduplication should use the event ID.
- Temporary failures may be retried; monitor pending, failed, and dead-letter counters.
- A successful HTTP response proves delivery, not human response.

### 9.3 Heartbeat fields

Heartbeat payloads summarize runtime and notification health. Treat `heartbeat` or recovery-type messages separately from detection events, and alert an administrator if queue or failure counts continue to rise.

---

## 10. Daily operating routine

### Start of shift

- Open Live Wall and confirm all expected cameras are present.
- Check for persistent Reconnecting, warm-up, or Error states.
- Open Event Center and review pending events from the previous shift.
- Confirm recent clips can be played and disk status is normal.
- Verify the notification receiver when the site procedure requires it.

### During alert handling

- Verify location and live conditions first.
- Follow emergency and escalation procedures.
- Record Confirmed or False Positive only after review.
- Add a useful false-positive reason when applicable.

### End-of-shift handover

- Handover unprocessed events and camera faults.
- Record unusual false alerts, misses, stream interruptions, and notification issues.
- Do not change thresholds or sampling settings without an approved change record and replay validation.

---

## 11. Frequently asked questions

### The preview is black but the camera is Online

Refresh once, then check whether the browser supports the stream and whether the first recording segment has closed. Report the camera name, time, and visible status to an administrator.

### The camera remains Reconnecting

Confirm the camera/NVR is powered and reachable. An administrator should test the same RTSP URL on the service host and check credentials, port 554, and codec.

### The camera remains in Recording warm-up

Wait for the first closed segment. If the state persists, check stream stability and FFmpeg logs.

### There are too many alerts

Record representative false positives. Review camera angle, steam/fog/reflections, target size, and policy using both positive and negative samples. Do not broadly increase thresholds without measuring misses.

### There are no alerts

Confirm the capability is enabled and the target is visible and large enough. Use authorized positive material. A live preview alone does not prove the model can recognize that view.

### The event has no video

Check whether the source was stable, recording had finished warming up, and the data disk was writable. Preserve the event ID and time for troubleshooting.

### The webhook received nothing

Check the saved URL, receiver logs, notification counters, network reachability, and receiver response time. Test with a controlled event.

### Does deleting a camera delete historical events?

No. Historical events remain until separately removed through Storage Management.

### Do parameter changes require a restart?

Per-camera settings saved in Camera Management normally apply live. Global `.env` changes require a service restart.

---

## 12. Quick reference

| Task | Page | Action |
|---|---|---|
| Check all camera states | Live Wall | Review badges and image freshness |
| Add or edit a camera | Camera Management | Enter RTSP/settings, save, verify Online |
| Review an alert | Event Center | Compare snapshots, play clip, check live view |
| Confirm a real event | Event Center | Select Confirmed after site verification |
| Record a false alert | Event Center | Mark False Positive and enter a reason |
| Export feedback | Event Center / Feedback | Download and review the package |
| Clean old evidence | Storage Management | Back up, select time range, confirm deletion |
| Diagnose a camera | Live Wall + administrator logs | Record camera, time, state, and symptoms |

---

**Prepared by: Shenzhen Dudumiao Technology Co., Ltd.**  
**Project: https://github.com/newtv-ai/smokefire**

