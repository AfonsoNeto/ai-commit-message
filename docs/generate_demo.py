#!/usr/bin/env python3
"""Generate docs/demo.cast and docs/demo.gif.

Runs real `ai-commit-message` commands against a local LLM server, then
assembles an asciicast v3 recording with realistic typing animation and the
real command outputs. The GIF is rendered with agg (asciinema gif generator).

Requirements: ai-commit-message installed and pointed at a running local LLM
server, git, and agg (https://github.com/asciinema/agg) on PATH.

Usage: python3 docs/generate_demo.py
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile

COLS, ROWS = 84, 13
PROMPT = "\x1b[1;32m$\x1b[0m "
REPO = None
EVENTS = []


def run(cmd, input_=None):
    return subprocess.run(
        cmd, shell=True, input=input_, capture_output=True, text=True, cwd=REPO
    )


def emit(data, delay=0.04):
    EVENTS[-1][0] = round(EVENTS[-1][0] + delay, 3)
    EVENTS.append([EVENTS[-1][0], "o", data])


def type_command(cmd):
    emit(PROMPT)
    for i in range(0, len(cmd), 4):
        emit(cmd[i:i + 4], 0.05)
    emit("\r\n", 0.12)


def main():
    global REPO
    REPO = tempfile.mkdtemp(prefix="acm-demo-")

    # Prepare a small demo repository with one staged change.
    run("git init -q && git config user.email demo@example.com")
    run("git config user.name Demo && git config commit.gpgsign false")
    run("printf 'def add(a, b):\\n    return a + b\\n\\nprint(add(1, 2))\\n' > calc.py")
    run("git add calc.py && git commit -qm 'chore: initial setup'")
    run(
        "printf 'def add(a, b):\\n"
        "    \\\"\\\"\\\"Return the sum of two numbers.\\\"\\\"\\\"\\n"
        "    if not isinstance(a, (int, float)) or not isinstance(b, (int, float)):\\n"
        "        raise TypeError(\\\"add() expects numbers\\\")\\n"
        "    return a + b\\n' > calc.py"
    )
    run("git add calc.py")

    # Run the real commands and capture their real outputs.
    suggest = run("ai-commit-message commit --message-only")
    if suggest.returncode != 0:
        sys.exit(f"demo generation failed: {suggest.stderr.strip()}")
    message = suggest.stdout.strip()

    apply_out = run("ai-commit-message commit", input_="y\n")
    if apply_out.returncode != 0:
        sys.exit(f"demo apply failed: {apply_out.stderr.strip()}")

    # Assemble the recording.
    EVENTS.append([0.0, "o", ""])
    emit("\x1b[2m# ai-commit-message: AI commit messages from a local LLM\x1b[0m\r\n\r\n", 0.8)

    type_command("ai-commit-message commit")
    emit("", 0.9)  # the model is thinking
    emit(message + "\r\n\r\n", 0.6)

    type_command("ai-commit-message commit")
    emit("", 0.9)
    emit(message + "\r\n", 0.4)
    emit("Commit with this message? (\x1b[1mY\x1b[0m/n) ", 0.5)
    emit("y\r\n", 0.4)
    emit("\x1b[32m" + run("git log --oneline -1").stdout.rstrip() + "\x1b[0m\r\n\r\n", 0.6)

    type_command("git log --oneline -2")
    emit("", 0.4)
    log_out = run("git log --oneline -2").stdout.rstrip().replace("\n", "\r\n")
    emit("\x1b[33m" + log_out + "\x1b[0m\r\n\r\n", 0.5)

    shutil.rmtree(REPO, ignore_errors=True)

    header = {
        "version": 3,
        "term": {"cols": COLS, "rows": ROWS},
        "timestamp": int(subprocess.run("date +%s", shell=True, capture_output=True, text=True).stdout.strip()),
        "command": "ai-commit-message",
    }
    here = os.path.dirname(os.path.abspath(__file__))
    cast_path = os.path.join(here, "demo.cast")
    with open(cast_path, "w") as f:
        f.write(json.dumps(header) + "\n")
        for event in EVENTS:
            f.write(json.dumps(event) + "\n")
    print(f"wrote {cast_path}")

    gif_path = os.path.join(here, "demo.gif")
    subprocess.run(
        [
            "agg", "--speed", "2", "--idle-time-limit", "1",
            "--theme", "github-dark", "--font-size", "15",
            cast_path, gif_path,
        ],
        check=True,
    )
    print(f"wrote {gif_path}")


if __name__ == "__main__":
    main()
