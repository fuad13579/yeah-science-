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

