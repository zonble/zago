#!/usr/bin/env python3
"""
zago Reference IPC Client in Python.
Demonstrates client registration, querying editor state, and pushing Dim Gray Ghost Overlays.
"""

import sys
import os
import socket
import json

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 zago_client.py <path_to_socket> [auth_token]")
        print("Example: python3 zago_client.py /tmp/zago-12345.sock secret-token")
        sys.exit(1)

    sock_path = sys.argv[1]
    auth_token = sys.argv[2] if len(sys.argv) > 2 else "secret-token"

    if not os.path.exists(sock_path):
        print(f"Error: Socket file '{sock_path}' does not exist.")
        sys.exit(1)

    print(f"Connecting to zago IPC socket at {sock_path}...")
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.connect(sock_path)

    # 1. Register Client Identity
    reg_payload = {
        "jsonrpc": "2.0",
        "method": "zago.client.register",
        "params": {
            "auth": auth_token,
            "clientId": "py-architect-bot",
            "clientName": "Architect-Bot",
            "agentType": "diagram_forge",
            "color": "cyan"
        },
        "id": 1
    }
    client.sendall(json.dumps(reg_payload).encode("utf-8") + b"\n")
    response_data = client.recv(4096).decode("utf-8")
    print("Registration Response:", response_data.strip())

    # 2. Query Cursor Position
    cursor_payload = {
        "jsonrpc": "2.0",
        "method": "zago.buffer.getCursor",
        "params": {"bufferTarget": "active"},
        "id": 2
    }
    client.sendall(json.dumps(cursor_payload).encode("utf-8") + b"\n")
    cursor_resp = client.recv(4096).decode("utf-8")
    print("Cursor Position Response:", cursor_resp.strip())

    cursor_info = json.loads(cursor_resp).get("result", {})
    target_line = cursor_info.get("line", 1)

    # 3. Push Dim Gray Ghost Text Overlay Proposal
    preview_payload = {
        "jsonrpc": "2.0",
        "method": "zago.overlay.showPreview",
        "params": {
            "auth": auth_token,
            "clientId": "py-architect-bot",
            "reason": "Drafted 3-step architecture diagram at cursor",
            "affectedFiles": [
                {
                    "filePath": "active",
                    "chunks": [
                        {
                            "targetLine": target_line,
                            "targetCol": 1,
                            "lines": [
                                "┌───────────────┐     ┌───────────────┐     ┌───────────────┐",
                                "│  Client App   │ ──► │  Auth Server  │ ──► │ Payment Gate  │",
                                "└───────────────┘     └───────────────┘     └───────────────┘"
                            ],
                            "insertMode": "2d_insert"
                        }
                    ]
                }
            ]
        },
        "id": 3
    }
    client.sendall(json.dumps(preview_payload).encode("utf-8") + b"\n")
    preview_resp = client.recv(4096).decode("utf-8")
    print("Push Overlay Response:", preview_resp.strip())
    print("\nCheck zago terminal screen! Alt+Y: Accept | Alt+N: Reject | Alt+i: Reason")

    client.close()

if __name__ == "__main__":
    main()
