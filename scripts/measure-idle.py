#!/usr/bin/env python3
"""Developer-only macOS process counters. No UI, device, location, or account reads.

Usage: python3 scripts/measure-idle.py PID [--seconds 300] [--interval 15]
Close PhonePing's windows and leave it idle during the measurement.
CPU times are converted from Mach ticks using the host timebase; memory values are bytes.
"""
import argparse
import ctypes
import json
import platform
import sys
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("pid", type=int)
parser.add_argument("--seconds", type=float, default=300)
parser.add_argument("--interval", type=float, default=15)
args = parser.parse_args()
if sys.platform != "darwin" or args.pid <= 0 or not (1 <= args.seconds <= 3600) or not (1 <= args.interval <= args.seconds):
    parser.error("Use a positive macOS PID, 1–3600 seconds, and an interval within that duration.")

class Usage(ctypes.Structure):
    _fields_ = [("uuid", ctypes.c_uint8 * 16)] + [(key, ctypes.c_uint64) for key in (
        "user_time", "system_time", "pkg_idle_wkups", "interrupt_wkups", "pageins",
        "wired_size", "resident_size", "phys_footprint", "proc_start_abstime", "proc_exit_abstime")]

lib = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
lib.proc_pid_rusage.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_void_p]
lib.proc_pid_rusage.restype = ctypes.c_int

class Timebase(ctypes.Structure):
    _fields_ = [("numer", ctypes.c_uint32), ("denom", ctypes.c_uint32)]

system = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
system.mach_timebase_info.argtypes = [ctypes.POINTER(Timebase)]
system.mach_timebase_info.restype = ctypes.c_int
timebase = Timebase()
if system.mach_timebase_info(ctypes.byref(timebase)) != 0 or timebase.denom == 0:
    raise RuntimeError("Could not read the CPU timebase.")

def sample():
    usage = Usage()
    if lib.proc_pid_rusage(args.pid, 0, ctypes.byref(usage)) != 0:
        raise OSError(ctypes.get_errno(), "Could not read process counters; the app must remain running.")
    return usage

first = sample()
footprints = [first.phys_footprint]
resident = [first.resident_size]
started = time.monotonic()
while (remaining := args.seconds - (time.monotonic() - started)) > 0:
    time.sleep(min(args.interval, remaining))
    last = sample()
    if last.proc_start_abstime != first.proc_start_abstime or last.proc_exit_abstime:
        raise RuntimeError("The measured process exited or changed; discard this run.")
    footprints.append(last.phys_footprint)
    resident.append(last.resident_size)
elapsed = time.monotonic() - started
cpu_seconds = (last.user_time + last.system_time - first.user_time - first.system_time) * timebase.numer / timebase.denom / 1e9
print(json.dumps({
    "macOS": platform.mac_ver()[0], "architecture": platform.machine(),
    "duration_seconds": round(elapsed, 3), "samples": len(footprints),
    "cpu_seconds": round(cpu_seconds, 6), "cpu_percent_one_core": round(100 * cpu_seconds / elapsed, 4),
    "physical_footprint_MiB_min_max": [round(min(footprints) / 2**20, 2), round(max(footprints) / 2**20, 2)],
    "resident_MiB_min_max": [round(min(resident) / 2**20, 2), round(max(resident) / 2**20, 2)],
    "package_idle_wakeups": last.pkg_idle_wkups - first.pkg_idle_wkups,
    "interrupt_wakeups": last.interrupt_wkups - first.interrupt_wkups,
    "limitations": "One process and interval; excludes Find My and does not measure battery life."
}, indent=2))
