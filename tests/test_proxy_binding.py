"""Exercise macOS interface binding with local SOCKS connections only."""
import os
import socket
import subprocess
import sys
import time


def recv_exact(sock, count):
    data = b""
    while len(data) < count:
        chunk = sock.recv(count - len(data))
        if not chunk:
            raise RuntimeError("Unexpected SOCKS EOF")
        data += chunk
    return data


def check(binary, interface, expected_success):
    with socket.socket() as target, socket.socket() as reservation:
        target.bind(("127.0.0.1", 0))
        target.listen(1)
        target.settimeout(2)
        reservation.bind(("127.0.0.1", 0))
        proxy_port = reservation.getsockname()[1]
        reservation.close()
        env = dict(os.environ, MACDPI_BIND_INTERFACE=interface)
        process = subprocess.Popen(
            [binary, "-i", "127.0.0.1", "-I", "0.0.0.0", "-p", str(proxy_port)],
            env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        try:
            deadline = time.monotonic() + 5
            while True:
                try:
                    sock = socket.create_connection(("127.0.0.1", proxy_port), 1)
                    break
                except OSError:
                    if process.poll() is not None or time.monotonic() > deadline:
                        raise
                    time.sleep(0.05)
            with sock:
                sock.settimeout(3)
                sock.sendall(b"\x05\x01\x00")
                assert recv_exact(sock, 2) == b"\x05\x00"
                port = target.getsockname()[1]
                sock.sendall(b"\x05\x01\x00\x01\x7f\x00\x00\x01" + port.to_bytes(2, "big"))
                success = recv_exact(sock, 2)[1] == 0
                assert success == expected_success, (interface, success)
                if success:
                    with target.accept()[0] as peer:
                        assert peer.getpeername()[0] == "127.0.0.1"
        finally:
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


check(sys.argv[1], "lo0", True)
check(sys.argv[1], "invalid_macdpi_interface", False)
print("Proxy binding: loopback succeeds; missing interface fails closed.")
