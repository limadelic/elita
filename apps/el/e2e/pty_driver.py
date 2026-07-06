#!/usr/bin/env python3
"""
PTY driver for testing claude wrap.
Spawns a process in a PTY and provides interface for:
- Capturing output
- Sending input
- Setting terminal size
- Detecting process exit
"""

import os
import sys
import pty
import signal
import subprocess
import time
import fcntl
import termios
import struct
import select

class PtyDriver:
    def __init__(self, rows=24, cols=80, timeout=60):
        self.rows = rows
        self.cols = cols
        self.timeout = timeout
        self.proc = None
        self.master_fd = None
        self.output_buffer = ""
        self.start_time = None
        self.exited = False
        self.exit_code = None

    def start(self, cmd_list):
        """Start a process in a PTY."""
        self.start_time = time.time()
        self.master_fd, slave_fd = pty.openpty()

        # Set slave size
        self._set_size(slave_fd)

        # Fork and exec
        pid = os.fork()
        if pid == 0:  # child
            os.close(self.master_fd)
            os.setsid()
            os.dup2(slave_fd, 0)  # stdin
            os.dup2(slave_fd, 1)  # stdout
            os.dup2(slave_fd, 2)  # stderr
            os.close(slave_fd)
            os.execvp(cmd_list[0], cmd_list)
            sys.exit(1)

        # parent
        os.close(slave_fd)
        self.proc = pid

        # Set master to non-blocking
        flags = fcntl.fcntl(self.master_fd, fcntl.F_GETFL)
        fcntl.fcntl(self.master_fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)

    def _set_size(self, fd):
        """Set terminal size via ioctl."""
        winsize = struct.pack('HHHH', self.rows, self.cols, 0, 0)
        fcntl.ioctl(fd, termios.TIOCSWINSZ, winsize)

    def send(self, data):
        """Send data to the PTY."""
        if self.master_fd is None or self.exited:
            raise RuntimeError("PTY not running")
        os.write(self.master_fd, data.encode() if isinstance(data, str) else data)

    def send_raw(self, data_bytes):
        """Send raw bytes to the PTY."""
        if self.master_fd is None or self.exited:
            raise RuntimeError("PTY not running")
        os.write(self.master_fd, data_bytes)

    def read_output(self):
        """Read available output from PTY."""
        try:
            data = os.read(self.master_fd, 4096)
            if data:
                self.output_buffer += data.decode('utf-8', errors='replace')
                return data
        except (OSError, IOError):
            pass
        return b''

    def capture_until(self, expected_text, timeout_secs=15):
        """
        Read output until expected_text appears or timeout.
        Returns (success, total_output).
        """
        deadline = time.time() + timeout_secs
        while time.time() < deadline:
            self._update_exit_status()
            if self.exited:
                break

            self.read_output()
            if expected_text in self.output_buffer:
                return True, self.output_buffer

            time.sleep(0.1)

        return False, self.output_buffer

    def _update_exit_status(self):
        """Check if process has exited."""
        if self.exited:
            return

        try:
            pid, status = os.waitpid(self.proc, os.WNOHANG)
            if pid != 0:
                self.exited = True
                self.exit_code = status >> 8
        except:
            pass

    def is_alive(self):
        """Check if process is still running."""
        self._update_exit_status()
        return not self.exited

    def kill(self, signal_num=signal.SIGTERM, wait_secs=5):
        """Kill the process."""
        if self.proc is None or self.exited:
            return

        os.kill(self.proc, signal_num)
        deadline = time.time() + wait_secs
        while time.time() < deadline:
            self._update_exit_status()
            if self.exited:
                return True
            time.sleep(0.1)

        return self.exited

    def wait_for_exit(self, timeout_secs=None):
        """Wait for process to exit."""
        timeout_secs = timeout_secs or self.timeout
        deadline = time.time() + timeout_secs

        while time.time() < deadline:
            self._update_exit_status()
            if self.exited:
                return True
            time.sleep(0.1)

        return self.exited

    def close(self):
        """Clean up resources."""
        if self.master_fd is not None:
            try:
                os.close(self.master_fd)
            except:
                pass
            self.master_fd = None

        if self.proc is not None and not self.exited:
            try:
                self.kill(signal.SIGKILL, wait_secs=1)
            except:
                pass

    def get_output(self):
        """Get all captured output."""
        return self.output_buffer

    def drain(self, timeout_secs=0.5):
        """Read all available output."""
        deadline = time.time() + timeout_secs
        while time.time() < deadline:
            data = self.read_output()
            if not data:
                time.sleep(0.05)
        return self.output_buffer
