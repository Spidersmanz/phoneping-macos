# Performance checks

PhonePing does no scheduled device scanning or permission polling. Permission is checked at launch, app activation, menu opening, and user actions. Discovery runs only after Refresh or Play Sound, with one operation in progress. Its tree traversal has depth, count, and time bounds; a set tracks visited Accessibility objects to avoid repeated linear searches.

These are source-level properties, not a battery-life claim. Find My has its own process and resource use.

## Controlled build 12 comparison, October 13, 2026

Preview 0.1.3 build 12, arm64, macOS 27.0.1. The maintainer quit and reopened PhonePing, confirmed Settings was closed, and left the menu bar app idle. Find My was absent before the measurement. No real PhonePing UI, permission query, discovery, or sound request was performed by the assistant during sampling. The process remained the same throughout. A separate fictional Settings preview was inspected and closed during the interval; its resource use is not included in these counters.

After the baseline, the maintainer selected Play Sound once from the menu with another app foreground, then confirmed audible ringing and that Find My stayed behind. The maintainer was asked to allow cleanup and leave PhonePing untouched after replying. Find My was absent at the start and end of the post-request sample. PhonePing's process ID matched the baseline before and after sampling; the measurement also detected no process replacement within either interval. No app rebuild, additional request, diagnostic, or UI inspection occurred during the second interval.

| Metric | Fresh launch, five minutes | After one menu request, five minutes |
| --- | --- | --- |
| Duration / samples | 300.005 seconds / 21 | 300.001 seconds / 21 |
| Process CPU time | 0.002070 seconds | 0.002409 seconds |
| Average CPU, one core | 0.0007% | 0.0008% |
| Physical footprint, min–max | 12.95–12.97 MiB | 18.86–18.94 MiB |
| Resident memory, min–max | 74.52–74.53 MiB | 86.80–86.84 MiB |
| Package-idle wakeups | 0 | 0 |
| Interrupt wakeups | 3 | 3 |

Idle CPU stayed low after this request. Physical footprint was about 6 MiB above the fresh baseline, with a narrow 0.08 MiB range during the post-request sample. A retained increase after one operation does not establish a leak; repeated-operation measurements are still needed. The earlier approximately 0.6% idle CPU was not reproduced in this menu-only run. Its cause remains unresolved, including whether opening Settings or diagnostics changes subsequent idle behavior.

The CPU conversion was checked again during this pass against a controlled workload's process clock: 0.200014 seconds from converted counters versus 0.200000 seconds from the clock. The readings cover PhonePing only. The intervals do not capture the request itself, its immediate recovery, Find My's active cost, repeated-use behavior, or battery life. The post-request sample began after the maintainer's reply, so it is a settled-idle observation, not a latency measurement.

## Reproduce an idle measurement

Build the release configuration locally, open PhonePing, close its windows, and let launch activity settle. Get PhonePing's PID from Activity Monitor, then run this developer-only script with Python 3:

```sh
python3 scripts/measure-idle.py PID --seconds 300 --interval 15
```

The script reads macOS process counters, not UI or device data. It reports CPU time, average use of one CPU core, physical footprint, resident memory, and wakeup deltas. It detects process replacement or exit. CPU counters are converted from Mach ticks using the host timebase; this calculation was checked against Python's process CPU clock with a controlled workload on the development Mac. The script is not included in the application and does not run in the background after measurement.

Record app/OS versions, architecture, permission state, window state, and recent app activity. Compare the same conditions between builds. Do not convert a single idle sample into a battery-life promise.

## Further measurements before public release

1. Repeat the settled post-request measurement after relevant changes. The build 12 comparison above covers one menu request; separately compare Settings/diagnostic use and repeated operations before attributing the earlier higher idle CPU.
2. Measure Refresh and one audible sound request, including Find My's CPU and memory separately.
3. Repeat several manual operations and verify memory settles rather than continuously growing.
4. Use Instruments on macOS to investigate any sustained CPU or repeated wakeups; do not add a keep-awake assertion to improve latency.

## Observed idle baseline, October 11, 2026

Preview 0.1.3 build 5, native arm64 release configuration, macOS 27.0.1. Settings was closed and a device name was saved. The rebuilt app had not yet regained Accessibility permission, and no discovery/sound operation ran during the sample. The app's process remained the same throughout.

| Metric | Observed |
| --- | --- |
| Duration / samples | 300.002 seconds / 21 |
| Process CPU time | 0.188371 seconds |
| Average CPU, one core | 0.0628% |
| Physical footprint, min–max | 24.70–25.56 MiB |
| Resident memory, min–max | 86.08–92.97 MiB |
| Package-idle wakeups | 0 |
| Interrupt wakeups | 3 |

Physical footprint and resident memory are different kernel counters; neither is the app's disk size. This is a pre-operation baseline, not a measure of Find My or permission-enabled discovery, sustained use, or battery life. Repeat after a successful sound request and compare multiple runs before making performance claims.


## Post-request sample, build 7

October 11, 2026; preview 0.1.3 build 7, native arm64 release configuration, macOS 27.0.1. Permission was Allowed, a device was selected, and a sound request had succeeded with the maintainer confirming delivery. Discovery, a read-only diagnostic, and the successful request had all completed before sampling. No further PhonePing operations or app rebuild occurred during the sample. The process remained the same throughout.

A settings close action was issued before sampling, but the desktop tool had continued to report settings after earlier close requests. Final window visibility was not independently verified. Treat this as an app-idle sample, not a verified windows-closed baseline directly comparable to build 5.

| Metric | Observed |
| --- | --- |
| Duration / samples | 300.005 seconds / 21 |
| Process CPU time | 1.820411 seconds |
| Average CPU, one core | 0.6068% |
| Physical footprint, min–max | 37.24–39.16 MiB |
| Resident memory, min–max | 80.67–129.84 MiB |
| Package-idle wakeups | 99 |
| Interrupt wakeups | 397 |

This excludes Find My and does not establish battery impact, request cost, or sustained-use memory behavior. CPU and wakeups were higher than in the earlier pre-operation sample, under different permission, app-history, and potentially window conditions. Repeat with window state independently verified and compare like-for-like conditions before attributing the difference or claiming negligible impact.


## Windows-closed sample after restart, build 9

October 11, 2026; preview 0.1.3 build 9, native arm64 release configuration, macOS 27.0.1. The maintainer confirmed Settings was closed and PhonePing remained in the menu bar. Find My was not running. The maintainer had quit and reopened PhonePing just before measurement, so this sample describes a fresh app process, not recovery in the same process after a sound request. Permission had been granted to this unchanged build; it was not queried again during sampling. The saved selection was not changed.

The first measurement attempt stopped before sampling because the earlier process had exited. It is excluded. The completed run began when the replacement process was about 38 seconds old; it retained the same process throughout. No PhonePing UI or sound action was performed by the assistant during the sample.

| Metric | Observed |
| --- | --- |
| Duration / samples | 300.005 seconds / 21 |
| Process CPU time | 0.003550 seconds |
| Average CPU, one core | 0.0012% |
| Physical footprint, min–max | 12.94–13.05 MiB |
| Resident memory, min–max | 69.34–74.77 MiB |
| Package-idle wakeups | 2 |
| Interrupt wakeups | 14 |

This provides a verified settings-closed idle observation after restart. It excludes Find My's active cost and does not establish battery impact or memory recovery after repeated requests. The earlier build 7 sample used a different app history and uncertain window state; it is not a controlled before/after comparison. A same-process post-request sample and repeated-use measurements remain public release checks.


## Same-process post-request sample, build 11

October 12, 2026; preview 0.1.3 build 11, arm64 release configuration, macOS 27.0.1. After the additional cold-launch request, the maintainer confirmed that the intended phone rang and Find My stayed behind. The diagnostic recorded playback and Normal quit confirmed. The maintainer then confirmed closing only Settings and leaving the menu bar app running.

The sampled process ID matched the one recorded before that request. The measurement detected no exit or process replacement during sampling. Find My was absent immediately before and after the measurement. Permission was Allowed during the preceding request; the app and its signature were unchanged. No app interaction, permission query, rebuild, or additional sound request was performed by the assistant during sampling.

| Metric | Observed |
| --- | --- |
| Duration / samples | 300.005 seconds / 21 |
| Process CPU time | 1.795965 seconds |
| Average CPU, one core | 0.5986% |
| Physical footprint, min–max | 36.27–37.47 MiB |
| Resident memory, min–max | 119.66–122.62 MiB |
| Package-idle wakeups | 181 |
| Interrupt wakeups | 684 |

This is a settled post-request idle sample in the same app process, taken after user confirmation and Settings closure. It does not measure the immediate memory peak, time to settle, Find My's active resource use, or battery life. Samples taken every 15 seconds can miss brief peaks. Settings visibility was confirmed by the maintainer; no desktop inspection was performed during sampling because it could disturb the app. The prior build 9 sample followed a restart, so it is not a controlled before/after comparison. Repeated-use recovery and active-request measurements remain open.


### Follow-up interpretation

The measured 0.5986% average CPU and wakeups are higher than the fresh-process build 9 observation, under different app history and window conditions. The difference is recorded for follow-up, not attributed to a confirmed leak or polling bug. A separate ten-second process sample taken afterward, at 10 ms sampling intervals, captured the main and event threads waiting for events and a worker waiting for work. It did not identify a running application loop; such a short sample can miss brief or periodic work and does not explain the five-minute totals. The raw process profile is kept outside the public project; only this summary is recorded here.

The next performance investigation should compare controlled fresh-launch and post-request intervals on the same build and use a longer activity/energy trace if the difference repeats. Do not claim negligible resource use or derive battery impact from these observations.
