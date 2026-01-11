#!/usr/bin/env python3
"""
Capture /context output from Claude interactive TUI using pexpect and extract
the context token usage summary (e.g., "66k/200k tokens (33%)").
"""
import io
import re
import sys
import time

try:
    import pexpect
except ImportError as import_error:
    PEXPECT_IMPORT_ERROR = import_error
    pexpect = None
else:
    PEXPECT_IMPORT_ERROR = None


ANSI_ESCAPE_RE = re.compile(r"\x1b(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
CONTEXT_USAGE_RE = re.compile(
    r"(?P<model>[^\s·]+.*?)\s*·\s*(?P<usage>[\d.,]+[kM]?/\d+(?:\.\d+)?[kM]?\s+tokens\s+\([\d.,]+%?\))"
)


def strip_ansi(text: str) -> str:
    """Remove ANSI escape sequences and stray carriage returns."""
    return ANSI_ESCAPE_RE.sub("", text).replace("\r", "")


def extract_context_summary(clean_text: str):
    """
    Return the model identifier line that contains the token usage summary.

    Example target:
        claude-sonnet-4-5-20250929 · 66k/200k tokens (33%)
    """
    for line in clean_text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        match = CONTEXT_USAGE_RE.search(stripped)
        if match:
            return stripped
    return None


def extract_usage_only(summary_line: str | None) -> str | None:
    """Extract just the '66k/200k tokens (33%)' portion from the summary line."""
    if not summary_line:
        return None
    match = CONTEXT_USAGE_RE.search(summary_line)
    if not match:
        return None
    return match.group("usage")


def capture_slash_command(command="/context", timeout=30, debug=False, wait_time=5, silent=False):
    """
    Spawn Claude TUI, send a slash command, and capture the output.

    Args:
        command: Slash command to execute (default: "/context").
        timeout: Maximum time to wait for responses.
        debug: If True, show all interactions.
        wait_time: Seconds to wait after sending command (default: 5).

    Returns:
        str: Captured output from the command.
    """
    if pexpect is None:
        raise RuntimeError("pexpect is not available")

    def emit(message=""):
        if not silent:
            print(message)

    emit(f"Spawning Claude TUI to execute '{command}'...\n")

    child = pexpect.spawn("claude", encoding="utf-8", timeout=timeout)
    child.setwinsize(40, 160)

    log_capture = io.StringIO()
    effective_debug = debug and not silent

    def drain_output(duration: float):
        """Continuously read from the child for the given duration."""
        end_time = time.time() + duration
        while time.time() < end_time:
            try:
                chunk = child.read_nonblocking(size=4096, timeout=0.2)
                if chunk:
                    log_capture.write(chunk)
                    if effective_debug:
                        sys.stdout.write(chunk)
                        sys.stdout.flush()
            except pexpect.TIMEOUT:
                continue
            except pexpect.EOF:
                return True
        return False

    try:
        emit("Waiting for initial output...")
        time.sleep(2)

        emit(f"Sending command: {command}")
        child.send(command)
        time.sleep(0.5)

        emit("Pressing Enter to execute command...")
        child.send("\r")

        emit(f"Capturing output for {wait_time} seconds...")
        eof_reached = drain_output(wait_time)

        emit("Pressing Escape to dismiss dialog...")
        child.send("\x1b")
        if not eof_reached:
            eof_reached = drain_output(1)

        emit("Sending /exit to terminate session...")
        child.sendline("/exit")
        if not eof_reached:
            drain_output(1)

        output = log_capture.getvalue()
        if effective_debug:
            print("\nRaw captured output length:", len(output))

        cleaned_output = strip_ansi(output)

        try:
            child.expect(pexpect.EOF, timeout=5)
        except Exception:
            child.close(force=True)

        return cleaned_output or output

    except pexpect.TIMEOUT as exc:
        print(f"\nTimeout: {exc}", file=sys.stderr)
        if debug:
            print(f"Buffer before timeout: {child.before}", file=sys.stderr)
            print(f"Buffer after timeout: {child.after}", file=sys.stderr)
        child.close(force=True)
        return None

    except Exception as exc:
        print(f"\nError: {exc}", file=sys.stderr)
        import traceback

        traceback.print_exc()
        child.close(force=True)
        return None


def write_error_log(path: str, message: str, silent: bool = False) -> None:
    """Persist an error message so downstream consumers can surface it."""
    if not path:
        return

    try:
        with open(path, "w", encoding="utf-8") as error_file:
            error_file.write(f"ERROR: {message}\n")
    except OSError as exc:
        if not silent:
            print(f"Warning: failed to write context log ({exc})", file=sys.stderr)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Capture Claude /context output")
    parser.add_argument(
        "command",
        nargs="?",
        default="/context",
        help="Slash command to execute (default: /context)",
    )
    parser.add_argument("--debug", action="store_true", help="Show all interactions")
    parser.add_argument(
        "--timeout", type=int, default=30, help="Timeout in seconds (default: 30)"
    )
    parser.add_argument(
        "--wait",
        type=int,
        default=5,
        help="Seconds to wait after sending command (default: 5)",
    )
    parser.add_argument(
        "--context-log",
        type=str,
        default="/tmp/context.log",
        help="File to write extracted context info (default: /tmp/context.log). Use empty string to skip.",
    )
    parser.add_argument(
        "--silent",
        action="store_true",
        help="Suppress normal output; only emit errors",
    )

    args = parser.parse_args()

    if args.debug and args.silent:
        parser.error("--debug and --silent cannot be used together")

    if PEXPECT_IMPORT_ERROR is not None:
        dependency_msg = "Missing dependency 'pexpect'. Install with 'pip install --user pexpect'."
        write_error_log(args.context_log, dependency_msg, args.silent)
        if not args.silent:
            print(dependency_msg, file=sys.stderr)
        sys.exit(1)

    output = capture_slash_command(
        args.command,
        timeout=args.timeout,
        debug=args.debug,
        wait_time=args.wait,
        silent=args.silent,
    )

    if output:
        if not args.silent:
            print("\n" + "=" * 60)
            print(f"OUTPUT FROM '{args.command}':")
            print("=" * 60)
            print(output)
            print("=" * 60)

        summary_line = extract_context_summary(output)
        usage_only = extract_usage_only(summary_line)

        if args.context_log:
            to_write = usage_only or summary_line or output
            try:
                with open(args.context_log, "w", encoding="utf-8") as context_file:
                    context_file.write(to_write + "\n")
                if not args.silent:
                    print(f"\nContext details saved to: {args.context_log}")
            except OSError as exc:
                print(f"\nWarning: Failed to write context log ({exc})", file=sys.stderr)

        if summary_line and not args.silent:
            print("\nCaptured Context Summary:")
            print("=" * 60)
            print(summary_line)
            if usage_only:
                print("-" * 60)
                print(f"Usage: {usage_only}")
            print("=" * 60)
        elif not summary_line:
            print("\nWarning: Could not locate context summary in output", file=sys.stderr)
    else:
        print("Failed to capture output or no output received", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
