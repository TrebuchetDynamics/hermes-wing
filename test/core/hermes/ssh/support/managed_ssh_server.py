#!/usr/bin/env python3
"""Disposable loopback SSH/HTTP fixture. No personal SSH config is read.

Start: <scratch>/venv/bin/python <this-file> start --scratch <scratch>
Probe: <scratch>/venv/bin/python <this-file> probe --scratch <scratch>
Stop:  <scratch>/venv/bin/python <this-file> stop --scratch <scratch>

Authentication accepts either the generated client key or generated password,
allowing independent tests of both client authentication paths. Neither anonymous
access nor other keys/passwords are accepted. This is not a two-factor server.
SIGTERM/SIGINT and the two-hour deadline remove generated credentials and ready
metadata. SIGKILL cannot run cleanup; rerun stop to remove leftover credentials.
"""

import argparse
import asyncio
import base64
import hashlib
import hmac
import json
import logging
import os
from pathlib import Path
import secrets
import signal
import sys

import asyncssh

USERNAME = "wing-test"
GENERATED = ("host_key", "client_key", "client_key.pub", "password", "ready.json")


def write_private(path, data):
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    fd = os.open(path, flags, 0o600)
    with os.fdopen(fd, "wb") as stream:
        stream.write(data)


def cleanup(scratch):
    for name in GENERATED:
        (scratch / name).unlink(missing_ok=True)


async def start(scratch):
    if (scratch / "ready.json").exists():
        raise RuntimeError("Existing fixture metadata; stop fixture first")
    connections = set()
    http_server = ssh_server = None
    try:
        host_key = asyncssh.generate_private_key("ssh-ed25519")
        client_key = asyncssh.generate_private_key("ssh-ed25519")
        password = secrets.token_urlsafe(32)
        write_private(scratch / "host_key", host_key.export_private_key())
        write_private(scratch / "client_key", client_key.export_private_key())
        write_private(scratch / "client_key.pub", client_key.export_public_key())
        write_private(scratch / "password", password.encode())

        async def http(reader, writer):
            try:
                await asyncio.wait_for(reader.readuntil(b"\r\n\r\n"), 5)
                body = b"owned-ssh-fixture\n"
                writer.write(b"HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
                             b"Cache-Control: no-store\r\nConnection: close\r\n"
                             b"Content-Length: " + str(len(body)).encode() +
                             b"\r\n\r\n" + body)
                await writer.drain()
            except (asyncio.TimeoutError, asyncio.IncompleteReadError,
                    asyncio.LimitOverrunError, ConnectionError):
                pass
            finally:
                writer.close()
                await writer.wait_closed()

        http_server = await asyncio.start_server(http, "127.0.0.1", 0, limit=8192)
        http_port = http_server.sockets[0].getsockname()[1]

        class Server(asyncssh.SSHServer):
            def connection_made(self, conn):
                self.conn = conn
                connections.add(conn)

            def connection_lost(self, exc):
                connections.discard(self.conn)

            def begin_auth(self, username):
                return True

            def password_auth_supported(self):
                return True

            def public_key_auth_supported(self):
                return True

            def validate_password(self, username, candidate):
                return username == USERNAME and hmac.compare_digest(candidate, password)

            def validate_public_key(self, username, key):
                return username == USERNAME and key == client_key.convert_to_public()

            def session_requested(self):
                return False

            def connection_requested(self, dest_host, dest_port, orig_host, orig_port):
                return dest_host == "127.0.0.1" and dest_port == http_port

            def server_requested(self, listen_host, listen_port):
                return False

        ssh_server = await asyncssh.create_server(
            Server, "127.0.0.1", 0, server_host_keys=[host_key],
            encoding=None, login_timeout=10, config=None,
            allow_scp=False, sftp_factory=None, kbdint_auth=False,
            agent_forwarding=False, x11_forwarding=False, allow_pty=False,
        )
        digest = hashlib.sha256(host_key.public_data).digest()
        ready = {
            "pid": os.getpid(), "host": "127.0.0.1", "username": USERNAME,
            "ssh_port": ssh_server.get_port(), "http_port": http_port,
            "host_sha256_bytes": list(digest),
            "host_sha256_base64": base64.b64encode(digest).decode(),
            "host_fingerprint": host_key.get_fingerprint("sha256"),
            "host_key_file": str(scratch / "host_key"),
            "client_key_file": str(scratch / "client_key"),
            "client_public_key_file": str(scratch / "client_key.pub"),
            "password_file": str(scratch / "password"),
            "authentication_modes": ["publickey", "password"],
            "authentication_policy": "either generated credential; no anonymous access",
        }
        write_private(scratch / "ready.json", json.dumps(ready).encode())
        stopped = asyncio.Event()
        loop = asyncio.get_running_loop()
        for sig in (signal.SIGINT, signal.SIGTERM):
            loop.add_signal_handler(sig, stopped.set)
        print("MANAGED_SSH_READY", flush=True)
        try:
            await asyncio.wait_for(stopped.wait(), 7200)
        except asyncio.TimeoutError:
            pass
    finally:
        if ssh_server:
            ssh_server.close()
            await ssh_server.wait_closed()
        for conn in tuple(connections):
            conn.close()
        await asyncio.gather(*(conn.wait_closed() for conn in tuple(connections)),
                             return_exceptions=True)
        if http_server:
            http_server.close()
            await http_server.wait_closed()
        cleanup(scratch)
        print("MANAGED_SSH_STOPPED", flush=True)


async def probe(scratch):
    ready = json.loads((scratch / "ready.json").read_text())

    class PinnedClient(asyncssh.SSHClient):
        def validate_host_public_key(self, host, addr, port, key):
            return hmac.compare_digest(
                hashlib.sha256(key.public_data).digest(),
                bytes(ready["host_sha256_bytes"]))

    common = dict(host="127.0.0.1", port=ready["ssh_port"], username=USERNAME,
                  known_hosts=(), client_factory=PinnedClient, agent_path=None,
                  config=None)
    checks = []
    for mode in ("publickey", "password"):
        credentials = (dict(client_keys=[ready["client_key_file"]]) if mode == "publickey"
                       else dict(client_keys=[], password=Path(ready["password_file"]).read_text()))
        async with asyncssh.connect(**common, **credentials) as conn:
            reader, writer = await conn.open_connection("127.0.0.1", ready["http_port"])
            writer.write(b"GET / HTTP/1.1\r\nHost: fixture\r\n\r\n")
            await writer.drain()
            response = await asyncio.wait_for(reader.read(), 5)
            assert response.endswith(b"owned-ssh-fixture\n")
            writer.close()
            await writer.wait_closed()
            checks.append(mode + "_forward_ok")
            for host, port in (("localhost", ready["http_port"]),
                               ("127.0.0.1", ready["ssh_port"])):
                try:
                    await conn.open_connection(host, port)
                except asyncssh.ChannelOpenError:
                    checks.append(mode + "_unowned_forward_denied")
                else:
                    raise AssertionError("Unowned forwarding accepted")
            try:
                await conn.run("ignored", check=True)
            except asyncssh.ChannelOpenError:
                checks.append(mode + "_session_denied")
            else:
                raise AssertionError("Session accepted")
            try:
                await conn.forward_remote_port("127.0.0.1", 0, "127.0.0.1", ready["http_port"])
            except asyncssh.ChannelListenError:
                checks.append(mode + "_remote_listener_denied")
            else:
                raise AssertionError("Remote listener accepted")
    for credentials in (dict(client_keys=[]),
                        dict(client_keys=[], password="invalid-fixture-password"),
                        dict(client_keys=[asyncssh.generate_private_key("ssh-ed25519")])):
        try:
            async with asyncssh.connect(**common, **credentials):
                raise AssertionError("Invalid credential accepted")
        except asyncssh.PermissionDenied:
            checks.append("invalid_or_absent_credential_denied")
    print(json.dumps({"ready": True, "checks": checks}))


def stop(scratch):
    ready_path = scratch / "ready.json"
    if not ready_path.exists():
        cleanup(scratch)
        return
    ready = json.loads(ready_path.read_text())
    pid = ready["pid"]
    try:
        command = Path(f"/proc/{pid}/cmdline").read_bytes().split(b"\0")
    except FileNotFoundError:
        cleanup(scratch)
        return
    if str(Path(__file__).resolve()).encode() not in command or b"start" not in command:
        raise RuntimeError("PID no longer belongs to this fixture")
    os.kill(pid, signal.SIGTERM)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("start", "probe", "stop"))
    parser.add_argument("--scratch", type=Path, required=True)
    args = parser.parse_args()
    os.umask(0o077)
    scratch = args.scratch.resolve()
    scratch.mkdir(parents=True, exist_ok=True, mode=0o700)
    scratch.chmod(0o700)
    logging.disable(logging.CRITICAL)
    if args.action == "stop":
        stop(scratch)
    else:
        asyncio.run(start(scratch) if args.action == "start" else probe(scratch))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        # Exception text can carry endpoint or authentication details.
        print("MANAGED_SSH_ERROR " + type(exc).__name__, file=sys.stderr)
        sys.exit(1)
