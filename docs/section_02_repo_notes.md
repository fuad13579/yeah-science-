# Mouse Command Path Trace

The existing mouse control flow was traced before implementing keyboard control.

Flow:

DrivePad.qml
    |
    | station.setDrive(left, right)
    ↓
Station.setDrive()
    |
    | validates command and scales wheel values
    ↓
Station._send_drive()
    |
    | encode("drive", seq, left, right)
    ↓
Packet encoder
    |
    | JSON bytes
    ↓
link.send()
    |
    | UDP socket.sendto()
    ↓
Simulator socket.recvfrom()
    |
    | decode(raw)
    ↓
rover.command(packet, now)
    |
    ↓
rover.step()

The keyboard implementation will reuse this existing path instead of creating a new communication system.

#Mouse overlap policy

the latest input event wins. Pressing mouse Left while holding W cleared the remembered W and commanded a left turn. Pressing D while still holding mouse Left replaced that with a right turn; releasing D stopped the rover even though the mouse remained held.





##


connected = Property(bool, lambda self: self._online, notify=changed) (from controller.py)

CONNECTED now means UDP socket is open, not that the rover is replying.

When the simulator is killed, the station's UDP socket itself does not necessarily fail. Therefore _online stays True, and the UI keeps claiming CONNECTED.

the updated four steps will be:

DISCONNECTED = UDP link closed
WAITING      = link open, but no valid telemetry received yet
LIVE         = valid telemetry received within stale_after_ms
STALE        = telemetry was received before, but is now too old


# Section 02 — Let Him Cook

## 1. Keyboard Teleoperation

I traced the existing mouse-control path before adding keyboard input:

`DrivePad.qml -> station.setDrive() -> _send_drive() -> encode() -> UDP -> simulator -> rover.command()`

The keyboard controls reuse this same command path instead of creating a separate transport path.

### Implemented

- WASD movement
- Arrow-key aliases
- Held-key state tracking
- Immediate stop/recalculation when keys are released
- Opposing directions cancel
- Forward + turn mixing
- W and Up behave as aliases without doubling speed
- Qt auto-repeat events are ignored
- Losing focus clears keyboard movement
- DrivePad focus is restored after enabling the drive link

### Bugs found

**Focus bug:**  
After clicking `Enable Drive Link`, focus stayed on the button. Pressing `W` immediately afterwards did not reach the DrivePad.

**Fix:**  
Return focus to the DrivePad after enabling the drive link.

**Auto-repeat bug:**  
Qt could generate auto-repeat release events while a key was still physically held. This temporarily removed the key from the held-key state and caused a short stop/stutter.

**Fix:**  
Ignore auto-repeat press/release events and only update movement state on real key transitions.

---

## 2. Connection and Telemetry State

### Problem investigated

The original application displayed `CONNECTED` whenever the local UDP link was open.

`station.connected` was backed by `_online`, and `_online` became `True` immediately after `link.open()`. Therefore, opening the socket was being treated as proof that the rover was alive.

This was misleading because UDP can remain open even when the simulator/rover is no longer running.

The telemetry store already records the time of the last valid telemetry packet using `received_at`, so I used this timestamp together with `stale_after_ms` to determine rover liveness.

### Connection states

I introduced four states:

- `DISCONNECTED` — local datalink is closed
- `WAITING` — datalink is open but no valid telemetry has been received
- `LIVE` — valid telemetry was received recently
- `STALE` — previously valid telemetry is older than `stale_after_ms`

Opening the UDP socket no longer proves that the rover is responding.

Only a successfully decoded telemetry packet refreshes the telemetry timestamp.

### Stale telemetry

The default stale timeout is controlled by:

`stale_after_ms`

When telemetry becomes stale:

- the UI changes to `STALE`
- telemetry values are shown as unavailable (`--`)
- old values are not presented as current measurements
- the drive link is disarmed
- stored drive commands are reset to zero

I used `--` rather than `0` for unavailable telemetry because zero can be a valid measurement.

### No silent resume

If telemetry is lost while driving, the station clears the previous command and disarms the drive link.

When telemetry later returns, the state can change from:

`STALE -> LIVE`

but the previous movement command is not automatically resumed.

The operator must enable the drive link again and provide fresh input before movement resumes.

---

## 3. Scenario Testing

Commands used:

```bash
python -m simulator --scenario normal
python -m simulator --scenario quiet
python -m simulator --scenario noise
python -m simulator --scenario dropout