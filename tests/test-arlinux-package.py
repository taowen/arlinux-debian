#!/usr/bin/env python3
"""Verify Arlinux exposes only its necessary speech integration."""

import importlib
import inspect
import json
import os
from pathlib import Path
import sys
import tempfile
from unittest import mock


product = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(product / "guest"))
arlinux = importlib.import_module("arlinux")
tts = importlib.import_module("arlinux._tts")

assert arlinux.__all__ == ("speak",)
for name in arlinux.__all__:
    function = getattr(arlinux, name)
    assert callable(function)
    assert inspect.getdoc(function)
assert not inspect.iscoroutinefunction(arlinux.speak)
assert "automatically interrupts" in inspect.getdoc(arlinux.speak)
assert "upstream ``dogtail`` and" in inspect.getdoc(arlinux)
assert not hasattr(arlinux, "find")
assert not hasattr(arlinux, "press")


class Worker:
    next_pid = 41000

    def __init__(self, command, **kwargs):
        Worker.next_pid += 1
        self.pid = Worker.next_pid
        calls.append((command, kwargs))

    def wait(self):
        return 0


calls = []
terminated = []
with tempfile.TemporaryDirectory() as runtime:
    os.environ["XDG_RUNTIME_DIR"] = runtime
    with mock.patch.object(tts.subprocess, "Popen", Worker), mock.patch.object(
        tts, "_terminate_worker", terminated.append
    ):
        assert arlinux.speak("first message") is True
        first_state = json.loads(Path(runtime, "arlinux-tts-state.json").read_text())
        assert arlinux.speak("second message") is True
        second_state = json.loads(Path(runtime, "arlinux-tts-state.json").read_text())

assert terminated == [0, first_state["worker_pid"]]
assert first_state["token"] != second_state["token"]
assert calls[0][0][1:4] == ["-m", "arlinux._tts", "--worker"]
assert calls[0][1]["start_new_session"] is True
assert calls[0][1]["stdout"] is tts.subprocess.DEVNULL
assert calls[0][1]["stderr"] is tts.subprocess.DEVNULL

print("PASS: arlinux keeps only TTS and leaves accessibility to upstream APIs")
