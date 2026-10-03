## Repeatable Regression Check

I used the simulator's built-in scenarios as a repeatable manual regression check.

### 1. No simulator

Run:

`python -m app`

Click Connect with no simulator running.

Expected:
- state becomes `WAITING`
- drive cannot be enabled
- no telemetry is treated as live

### 2. Normal

Run:

`python -m simulator --scenario normal`

Expected:
- `WAITING -> LIVE`
- valid telemetry appears
- drive can be enabled

### 3. Quiet

Run:

`python -m simulator --scenario quiet`

Expected:
- no valid telemetry means the rover must not be considered `LIVE`
- drive remains unavailable

### 4. Noise

Run:

`python -m simulator --scenario noise`

Expected:
- malformed/arbitrary packets do not prove rover liveness
- invalid packets are rejected/logged
- only valid telemetry can produce `LIVE`

### 5. Dropout

Run:

`python -m simulator --scenario dropout`

Test while driving.

Expected:

`LIVE -> STALE -> LIVE`

During `STALE`:
- drive is disarmed
- command becomes `0.00 / 0.00`
- stale telemetry is clearly marked

After telemetry returns:
- rover remains stopped
- re-enabling alone does not resume movement
- fresh keyboard input is required

### Regression result

I can rerun the same sequence after future changes to confirm that the connection-state and no-silent-resume behavior still works.