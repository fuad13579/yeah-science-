import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: drivePad

    spacing: 8
    focus: true

   
    // ADDED: KEYBOARD TELEOP STATE
   

    property var pressedKeys: ({})

    function isMovementKey(key) {
        return key === Qt.Key_W ||
               key === Qt.Key_A ||
               key === Qt.Key_S ||
               key === Qt.Key_D ||
               key === Qt.Key_Up ||
               key === Qt.Key_Left ||
               key === Qt.Key_Down ||
               key === Qt.Key_Right
    }

    function clearKeyboardState() {
        pressedKeys = ({})
        station.stop()
    }

    function updateKeyboardDrive() {
        // W and Up are aliases.
        // Holding both must still count as one forward input.
        var forward =
                pressedKeys[Qt.Key_W] ||
                pressedKeys[Qt.Key_Up]

        // S and Down are aliases.
        var reverse =
                pressedKeys[Qt.Key_S] ||
                pressedKeys[Qt.Key_Down]

        // A and Left are aliases.
        var turnLeft =
                pressedKeys[Qt.Key_A] ||
                pressedKeys[Qt.Key_Left]

        // D and Right are aliases.
        var turnRight =
                pressedKeys[Qt.Key_D] ||
                pressedKeys[Qt.Key_Right]

        // Opposing directions cancel.
        var forwardAxis =
                (forward ? 1 : 0) -
                (reverse ? 1 : 0)

        var turnAxis =
                (turnRight ? 1 : 0) -
                (turnLeft ? 1 : 0)

        // Differential-drive mixing.
        var leftCommand = forwardAxis + turnAxis
        var rightCommand = forwardAxis - turnAxis

        // Keep normalized wheel commands within [-1, 1].
        leftCommand =
                Math.max(-1, Math.min(1, leftCommand))

        rightCommand =
                Math.max(-1, Math.min(1, rightCommand))

        if (leftCommand === 0 && rightCommand === 0) {
            station.stop()
        } else {
            station.setDrive(leftCommand, rightCommand)
        }
    }

    // Ignore Qt-generated auto-repeat events.
    // Only the real initial press and real final release
    // modify the remembered keyboard state.
    Keys.onPressed: function(event) {
        if (!isMovementKey(event.key))
            return

        if (event.isAutoRepeat) {
            event.accepted = true
            return
        }

        pressedKeys[event.key] = true
        updateKeyboardDrive()

        event.accepted = true
    }

    Keys.onReleased: function(event) {
        if (!isMovementKey(event.key))
            return

        if (event.isAutoRepeat) {
            event.accepted = true
            return
        }

        delete pressedKeys[event.key]
        updateKeyboardDrive()

        event.accepted = true
    }

    // If keyboard focus leaves the drive pad,
    // forget held movement keys and request stop.
    //
    // This also makes mouse interaction naturally take over
    // without modifying the authority-provided mouse handlers.
    onActiveFocusChanged: {
        if (!activeFocus)
            clearKeyboardState()
    }

    // =========================================================
    // AUTHORITY-PROVIDED UI / MOUSE CONTROLS BELOW
    // UNCHANGED
    // =========================================================

    RowLayout {
        spacing: 6
        Rectangle {
            width: 3; height: 10; color: "#f3c623"; radius: 1
        }
        Label {
            text: "// TELEOPERATIONS COMMAND DECK"
            color: "#00e676"
            font.letterSpacing: 1.5
            font.pixelSize: 10
            font.bold: true
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
        }
    }

    Label {
        text: "Hold control pad button to command drive"
        color: "#dce5ef"
        font.pixelSize: 13
        font.bold: true
    }

    GridLayout {
        columns: 3
        rowSpacing: 6; columnSpacing: 6

        Item { Layout.preferredWidth: 72 }
        Button {
            objectName: "forwardButton"
            text: "▲ W  FWD"
            Layout.preferredWidth: 96
            enabled: station.armed
            onPressed: station.setDrive(1, 1)
            onReleased: station.stop()
            onCanceled: station.stop()
        }
        Item { Layout.preferredWidth: 72 }

        Button {
            text: "◀ A  LEFT"
            Layout.preferredWidth: 84
            enabled: station.armed
            onPressed: station.setDrive(-1, 1)
            onReleased: station.stop()
            onCanceled: station.stop()
        }
        Button {
            text: "✖ STOP"
            Layout.preferredWidth: 96
            palette.button: "#e63946"
            palette.buttonText: "#ffffff"
            onClicked: station.stop()
        }
        Button {
            text: "RIGHT  D ▶"
            Layout.preferredWidth: 84
            enabled: station.armed
            onPressed: station.setDrive(1, -1)
            onReleased: station.stop()
            onCanceled: station.stop()
        }

        Item { Layout.preferredWidth: 72 }
        Button {
            text: "▼ S  REV"
            Layout.preferredWidth: 96
            enabled: station.armed
            onPressed: station.setDrive(-1, -1)
            onReleased: station.stop()
            onCanceled: station.stop()
        }
        Item { Layout.preferredWidth: 72 }
    }

    RowLayout {
        spacing: 8
        Label {
            text: "THROTTLE:"
            color: "#7a8b9e"
            font.pixelSize: 10
            font.bold: true
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
        }
        Slider {
            Layout.fillWidth: true
            from: 0.1; to: 1.0; value: station.speed
            onMoved: station.setSpeed(value)
        }
        Label {
            text: Math.round(station.speed * 100) + "%"
            color: "#f3c623"
            font.bold: true
            font.pixelSize: 12
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
        }
    }

    Rectangle {
        Layout.fillWidth: true; height: 26
        color: "#0a0e13"
        radius: 3
        border.color: "#182330"
        Label {
            anchors.centerIn: parent
            text: "CMD_SPEED: L=" + station.leftCommand.toFixed(2) + " | R=" + station.rightCommand.toFixed(2)
            color: "#00e676"
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
            font.pixelSize: 11
            font.bold: true
        }
    }

    Rectangle {
        Layout.fillWidth: true; height: 22
        color: "#1d170b"
        radius: 2
        border.color: "#f3c623"
        border.width: 1
        Label {
            anchors.centerIn: parent
            text: "KEYBOARD TELEOP: IMPLEMENTED"
            color: "#f3c623"
            font.pixelSize: 9
            font.bold: true
            font.family: Qt.platform.os === "windows" ? "Consolas" : "monospace"
            font.letterSpacing: 0.5
        }
    }
}
