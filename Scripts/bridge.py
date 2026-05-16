#!/usr/bin/env python3
"""Apple TV Control Bridge — JSON stdin/stdout protocol with pairing support."""

import asyncio
import json
import logging
import os
import sys

from pyatv import connect, const, pair, scan
from pyatv.protocols.companion.api import InputAction
from pyatv.storage.file_storage import FileStorage

# Commands that support press-and-hold (InputAction.Hold)
HOLDABLE_COMMANDS = {"up", "down", "left", "right", "select", "menu", "home"}

CREDENTIALS_DIR = os.path.expanduser("~/.appletv_control")
CREDENTIALS_FILE = os.path.join(CREDENTIALS_DIR, "credentials.json")


def ensure_credentials_dir():
    os.makedirs(CREDENTIALS_DIR, exist_ok=True)


class BridgeState:
    def __init__(self):
        self.atv = None
        self.config = None
        self.pairing_handler = None
        self.connected = False


async def handle_commands():
    logging.disable(logging.CRITICAL)
    ensure_credentials_dir()

    loop = asyncio.get_event_loop()
    storage = FileStorage(CREDENTIALS_FILE, loop)
    state = BridgeState()

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            respond({"type": "error", "message": "invalid json"})
            continue

        action = msg.get("action", "")

        if action == "scan":
            await do_scan(state, loop, storage)

        elif action == "connect":
            await do_connect(state, loop, storage, msg.get("identifier", ""))

        elif action == "begin_pairing":
            await do_begin_pairing(state, loop, storage)

        elif action == "submit_pin":
            await do_submit_pin(state, loop, storage, msg.get("pin", ""))

        elif action == "command":
            await do_command(state, msg.get("command", ""))

        elif action == "hold_command":
            await do_hold_command(state, msg.get("command", ""), msg.get("duration", 1.0))

        elif action == "disconnect":
            await do_disconnect(state)

        elif action == "quit":
            await do_disconnect(state)
            respond({"type": "bye"})
            sys.exit(0)

        else:
            respond({"type": "error", "message": f"unknown action: {action}"})


async def do_scan(state, loop, storage):
    try:
        devices = await scan(loop=loop, timeout=5, storage=storage)
        device_list = []
        for d in devices:
            # Check pairing status for Companion service
            paired = False
            for svc in d.services:
                if svc.protocol == const.Protocol.Companion:
                    if svc.pairing == const.PairingRequirement.NotNeeded or svc.credentials:
                        paired = True
                    break

            device_list.append({
                "name": d.name,
                "identifier": d.identifier,
                "address": str(d.address),
                "device_info": str(d.device_info) if d.device_info else None,
                "paired": paired,
            })
        respond({"type": "scan_result", "devices": device_list})
    except Exception as e:
        respond({"type": "error", "message": f"scan failed: {e}"})


async def do_connect(state, loop, storage, identifier):
    # Clean up any existing connection
    if state.atv:
        try:
            state.atv.close()
        except Exception:
            pass
        state.atv = None
        state.connected = False

    # Find device
    try:
        devices = await scan(loop=loop, timeout=5, storage=storage, identifier=identifier)
    except Exception as e:
        respond({"type": "error", "message": f"scan failed: {e}"})
        return

    if not devices:
        respond({"type": "error", "message": "device not found"})
        return

    state.config = devices[0]
    dev = state.config

    # Check if Companion pairing is needed
    needs_pairing = False
    for svc in dev.services:
        if svc.protocol == const.Protocol.Companion:
            if svc.pairing == const.PairingRequirement.Mandatory and not svc.credentials:
                needs_pairing = True
            break

    if needs_pairing:
        respond({
            "type": "pairing_required",
            "name": dev.name,
            "identifier": dev.identifier,
            "message": "This Apple TV needs to be paired. Click 'Pair' — a PIN will appear on your TV screen.",
        })
        return

    # Connect
    try:
        state.atv = await connect(
            config=dev, protocol=const.Protocol.Companion, loop=loop, storage=storage
        )
        state.connected = True
        respond({"type": "connected", "name": dev.name})
    except Exception as e:
        # If connection fails with credentials, suggest re-pairing
        respond({"type": "error", "message": f"connect failed: {e}"})
        respond({
            "type": "pairing_required",
            "name": dev.name,
            "identifier": dev.identifier,
            "message": "Connection failed. Re-pairing may be needed. Click 'Pair' to start.",
        })


async def do_begin_pairing(state, loop, storage):
    if not state.config:
        respond({"type": "error", "message": "no device selected — select a device first"})
        return

    try:
        state.pairing_handler = await pair(
            state.config, const.Protocol.Companion, loop=loop, storage=storage
        )
        await state.pairing_handler.begin()
        respond({
            "type": "pairing_started",
            "message": "Enter the PIN shown on your Apple TV screen",
        })
    except Exception as e:
        respond({"type": "error", "message": f"pairing failed: {e}"})


async def do_submit_pin(state, loop, storage, pin):
    if not state.pairing_handler:
        respond({"type": "error", "message": "no active pairing — select a device and pair first"})
        return

    try:
        state.pairing_handler.pin(int(pin))
        await state.pairing_handler.finish()

        if state.pairing_handler.has_paired:
            respond({"type": "pairing_success", "message": "Paired! Connecting..."})

            # Connect — credentials are in storage now
            try:
                state.atv = await connect(
                    config=state.config,
                    protocol=const.Protocol.Companion,
                    loop=loop,
                    storage=storage,
                )
                state.connected = True
                respond({"type": "connected", "name": state.config.name})
            except Exception as e:
                respond({"type": "error", "message": f"paired but connect failed: {e}"})
        else:
            respond({"type": "error", "message": "Pairing did not complete. Wrong PIN?"})

    except ValueError:
        respond({"type": "error", "message": "Invalid PIN. Enter only numbers."})
    except Exception as e:
        respond({"type": "error", "message": f"PIN submission failed: {e}"})


async def do_command(state, cmd):
    if not state.atv or not state.connected:
        respond({"type": "error", "message": "not connected"})
        return

    try:
        rc = state.atv.remote_control
        method = getattr(rc, cmd, None)
        if method is None:
            respond({"type": "error", "message": f"unknown command: {cmd}"})
            return
        await method()
        respond({"type": "ok"})
    except Exception as e:
        respond({"type": "error", "message": f"command '{cmd}' failed: {e}"})


async def do_hold_command(state, cmd, duration):
    """Send a press-and-hold command using InputAction.Hold."""
    if not state.atv or not state.connected:
        respond({"type": "error", "message": "not connected"})
        return

    if cmd not in HOLDABLE_COMMANDS:
        # Fall back to regular command
        await do_command(state, cmd)
        return

    try:
        rc = state.atv.remote_control
        method = getattr(rc, cmd, None)
        if method is None:
            respond({"type": "error", "message": f"unknown command: {cmd}"})
            return
        await method(action=InputAction.Hold)
        respond({"type": "ok"})
    except Exception as e:
        respond({"type": "error", "message": f"hold command '{cmd}' failed: {e}"})


async def do_disconnect(state):
    try:
        if state.atv:
            state.atv.close()
    except Exception:
        pass
    state.atv = None
    state.connected = False
    state.config = None
    respond({"type": "disconnected"})


def respond(data):
    sys.stdout.write(json.dumps(data) + "\n")
    sys.stdout.flush()


if __name__ == "__main__":
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 1)
    asyncio.run(handle_commands())
