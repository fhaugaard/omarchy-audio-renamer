import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Model.js" as Model

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  property var devices: []
  property bool loading: false
  property string statusMessage: ""
  property string statusType: "info" // "info", "success", "error"

  readonly property var sinks: {
    var list = []
    for (var i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].kind === "sink") list.push(devices[i])
    }
    return list
  }

  readonly property var sources: {
    var list = []
    for (var i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].kind === "source") list.push(devices[i])
    }
    return list
  }

  function open(payloadJson) {
    opened = true
    statusMessage = ""
    refreshDevices()
    Qt.callLater(function() {
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    opened = false
  }

  function dismiss() {
    opened = false
    if (shell && typeof shell.hide === "function") {
      shell.hide((manifest && manifest.id) || "skye.audio-renamer")
    }
  }

  function refreshDevices() {
    loading = true
    listProc.running = false
    listProc.running = true
  }

  function setAlias(nodeName, alias) {
    if (!alias || !alias.trim()) {
      statusMessage = "Alias cannot be empty."
      statusType = "error"
      return
    }
    statusMessage = "Applying alias…"
    statusType = "info"
    loading = true
    setProc.command = ["omarchy-audio-rename", "set", nodeName, alias.trim()]
    setProc.running = true
  }

  function resetAlias(nodeName) {
    statusMessage = "Resetting alias…"
    statusType = "info"
    loading = true
    resetProc.command = ["omarchy-audio-rename", "reset", nodeName]
    resetProc.running = true
  }

  function resetAll() {
    statusMessage = "Resetting all aliases…"
    statusType = "info"
    loading = true
    resetAllProc.command = ["omarchy-audio-rename", "reset-all"]
    resetAllProc.running = true
  }

  Timer {
    id: retryTimer
    interval: 400
    repeat: false
    onTriggered: {
      if (root.devices.length === 0 && root.opened) {
        root.refreshDevices()
      }
    }
  }

  Process {
    id: listProc
    command: ["omarchy-audio-rename", "list", "--json", "--all"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text || "[]")
          if (Array.isArray(parsed)) {
            root.devices = parsed
          }
        } catch (e) {
          root.statusMessage = "Error parsing device list"
          root.statusType = "error"
        }
      }
    }
    onExited: function(code) {
      root.loading = false
      if (code !== 0 && root.statusMessage === "") {
        root.statusMessage = "Failed to load audio devices"
        root.statusType = "error"
      } else if (root.devices.length === 0 && root.opened && !retryTimer.running) {
        retryTimer.start()
      }
    }
  }

  Process {
    id: setProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = String(text || "").trim()
        if (out) {
          root.statusMessage = out
          root.statusType = "success"
        }
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var err = String(text || "").trim()
        if (err) {
          root.statusMessage = err
          root.statusType = "error"
        }
      }
    }
    onExited: function(code) {
      root.refreshDevices()
    }
  }

  Process {
    id: resetProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = String(text || "").trim()
        if (out) {
          root.statusMessage = out
          root.statusType = "success"
        }
      }
    }
    onExited: function(code) {
      root.refreshDevices()
    }
  }

  Process {
    id: resetAllProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = String(text || "").trim()
        if (out) {
          root.statusMessage = out
          root.statusType = "success"
        }
      }
    }
    onExited: function(code) {
      root.refreshDevices()
    }
  }

  PanelWindow {
    id: panelWin
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omarchy-audio-renamer"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Backdrop Scrim
    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim || Qt.rgba(0, 0, 0, 0.72)

      MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
      }
    }

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: root.dismiss()

      // Main Dialog Card
      Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(Style.space(640), parent.width - Style.space(32))
        height: Math.min(Style.space(600), parent.height - Style.space(32))
        color: Color.menu.background
        radius: Style.cornerRadius
        clip: true

        border.color: Color.menu.border
        border.width: Math.max(1, Style.space(1))

        MouseArea {
          anchors.fill: parent
          onClicked: {} // Swallow clicks inside card
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.space(16)
          spacing: Style.space(12)

          // Header Row
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(10)

            Text {
              text: "󰓃"
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.title
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.space(2)

              Text {
                text: "Audio Device Renamer"
                color: Color.menu.text
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                text: "Set custom aliases for audio hardware across WirePlumber & Omarchy"
                color: Qt.darker(Color.menu.text, 1.4)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
            }

            Button {
              text: "󰑐"
              implicitWidth: Style.space(32)
              implicitHeight: Style.space(32)
              onClicked: root.refreshDevices()
            }

            Button {
              text: "✕"
              implicitWidth: Style.space(32)
              implicitHeight: Style.space(32)
              onClicked: root.dismiss()
            }
          }

          // Status / Message Banner
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: root.statusMessage ? Style.space(28) : 0
            visible: !!root.statusMessage
            color: root.statusType === "error" ? Qt.rgba(0.9, 0.2, 0.2, 0.2)
                 : root.statusType === "success" ? Qt.rgba(0.2, 0.8, 0.3, 0.2)
                 : Qt.rgba(0.2, 0.5, 0.9, 0.2)
            radius: Style.cornerRadiusSmall

            Text {
              anchors.centerIn: parent
              text: root.statusMessage
              color: root.statusType === "error" ? "#ff6b6b"
                   : root.statusType === "success" ? "#51cf66"
                   : Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }

          // Device List in ScrollView
          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Column {
              width: card.width - Style.space(32)
              spacing: Style.space(12)

              // Sinks Section
              Text {
                text: "OUTPUT DEVICES (SINKS)"
                color: Color.accent
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Text {
                visible: root.sinks.length === 0
                text: root.loading ? "Loading output devices…" : "(No audio output devices detected)"
                color: Qt.darker(Color.menu.text, 1.6)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.italic: true
              }

              Repeater {
                model: root.sinks

                delegate: Rectangle {
                  id: sinkItem
                  required property var modelData
                  required property int index

                  width: parent.width
                  implicitHeight: rowCol.implicitHeight + Style.space(16)
                  color: Style.controlFill(false, false, Color.menu.text, Color.accent)
                  radius: Style.cornerRadiusSmall
                  border.color: modelData.is_default ? Color.accent : Color.popups.border
                  border.width: 1

                  ColumnLayout {
                    id: rowCol
                    anchors.fill: parent
                    anchors.margins: Style.space(8)
                    spacing: Style.space(6)

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: Style.space(8)

                      Text {
                        text: Model.deviceGlyph(sinkItem.modelData)
                        color: sinkItem.modelData.is_default ? Color.accent : Color.menu.text
                        font.family: Style.font.family
                        font.pixelSize: Style.font.title
                      }

                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                          spacing: Style.space(6)
                          Text {
                            text: sinkItem.modelData.alias || sinkItem.modelData.description
                            color: Color.menu.text
                            font.family: Style.font.family
                            font.pixelSize: Style.font.body
                            font.bold: true
                            elide: Text.ElideRight
                          }
                          Rectangle {
                            visible: sinkItem.modelData.is_default
                            implicitWidth: defTxt.implicitWidth + Style.space(8)
                            implicitHeight: Style.space(16)
                            color: Color.accent
                            radius: Style.cornerRadiusSmall
                            Text {
                              id: defTxt
                              anchors.centerIn: parent
                              text: "DEFAULT"
                              color: Color.menu.background
                              font.family: Style.font.family
                              font.pixelSize: Style.font.caption - 2
                              font.bold: true
                            }
                          }
                          Rectangle {
                            visible: !!sinkItem.modelData.alias
                            implicitWidth: aliasTxt.implicitWidth + Style.space(8)
                            implicitHeight: Style.space(16)
                            color: Qt.rgba(0.3, 0.8, 0.4, 0.25)
                            radius: Style.cornerRadiusSmall
                            Text {
                              id: aliasTxt
                              anchors.centerIn: parent
                              text: "RENAMED"
                              color: "#51cf66"
                              font.family: Style.font.family
                              font.pixelSize: Style.font.caption - 2
                              font.bold: true
                            }
                          }
                        }

                        Text {
                          text: "Original: " + sinkItem.modelData.description + " (" + sinkItem.modelData.node_name + ")"
                          color: Qt.darker(Color.menu.text, 1.5)
                          font.family: Style.font.family
                          font.pixelSize: Style.font.caption
                          elide: Text.ElideRight
                          Layout.fillWidth: true
                        }
                      }
                    }

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: Style.space(6)

                      TextField {
                        id: aliasField
                        Layout.fillWidth: true
                        placeholderText: "Enter custom device name…"
                        text: sinkItem.modelData.alias || ""
                        onAccepted: root.setAlias(sinkItem.modelData.node_name, aliasField.text)
                      }

                      Button {
                        text: "Save"
                        implicitWidth: Style.space(64)
                        onClicked: root.setAlias(sinkItem.modelData.node_name, aliasField.text)
                      }

                      Button {
                        visible: !!sinkItem.modelData.alias
                        text: "Reset"
                        implicitWidth: Style.space(64)
                        onClicked: root.resetAlias(sinkItem.modelData.node_name)
                      }
                    }
                  }
                }
              }

              // Sources Section
              Item { width: parent.width; height: Style.space(8) }

              Text {
                text: "INPUT DEVICES (SOURCES)"
                color: Color.accent
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Text {
                visible: root.sources.length === 0
                text: root.loading ? "Loading input devices…" : "(No audio input devices detected)"
                color: Qt.darker(Color.menu.text, 1.6)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.italic: true
              }

              Repeater {
                model: root.sources

                delegate: Rectangle {
                  id: srcItem
                  required property var modelData
                  required property int index

                  width: parent.width
                  implicitHeight: srcCol.implicitHeight + Style.space(16)
                  color: Style.controlFill(false, false, Color.menu.text, Color.accent)
                  radius: Style.cornerRadiusSmall
                  border.color: modelData.is_default ? Color.accent : Color.popups.border
                  border.width: 1

                  ColumnLayout {
                    id: srcCol
                    anchors.fill: parent
                    anchors.margins: Style.space(8)
                    spacing: Style.space(6)

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: Style.space(8)

                      Text {
                        text: Model.deviceGlyph(srcItem.modelData)
                        color: srcItem.modelData.is_default ? Color.accent : Color.menu.text
                        font.family: Style.font.family
                        font.pixelSize: Style.font.title
                      }

                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                          spacing: Style.space(6)
                          Text {
                            text: srcItem.modelData.alias || srcItem.modelData.description
                            color: Color.menu.text
                            font.family: Style.font.family
                            font.pixelSize: Style.font.body
                            font.bold: true
                            elide: Text.ElideRight
                          }
                          Rectangle {
                            visible: srcItem.modelData.is_default
                            implicitWidth: defSrcTxt.implicitWidth + Style.space(8)
                            implicitHeight: Style.space(16)
                            color: Color.accent
                            radius: Style.cornerRadiusSmall
                            Text {
                              id: defSrcTxt
                              anchors.centerIn: parent
                              text: "DEFAULT"
                              color: Color.menu.background
                              font.family: Style.font.family
                              font.pixelSize: Style.font.caption - 2
                              font.bold: true
                            }
                          }
                          Rectangle {
                            visible: !!srcItem.modelData.alias
                            implicitWidth: aliasSrcTxt.implicitWidth + Style.space(8)
                            implicitHeight: Style.space(16)
                            color: Qt.rgba(0.3, 0.8, 0.4, 0.25)
                            radius: Style.cornerRadiusSmall
                            Text {
                              id: aliasSrcTxt
                              anchors.centerIn: parent
                              text: "RENAMED"
                              color: "#51cf66"
                              font.family: Style.font.family
                              font.pixelSize: Style.font.caption - 2
                              font.bold: true
                            }
                          }
                        }

                        Text {
                          text: "Original: " + srcItem.modelData.description + " (" + srcItem.modelData.node_name + ")"
                          color: Qt.darker(Color.menu.text, 1.5)
                          font.family: Style.font.family
                          font.pixelSize: Style.font.caption
                          elide: Text.ElideRight
                          Layout.fillWidth: true
                        }
                      }
                    }

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: Style.space(6)

                      TextField {
                        id: srcAliasField
                        Layout.fillWidth: true
                        placeholderText: "Enter custom device name…"
                        text: srcItem.modelData.alias || ""
                        onAccepted: root.setAlias(srcItem.modelData.node_name, srcAliasField.text)
                      }

                      Button {
                        text: "Save"
                        implicitWidth: Style.space(64)
                        onClicked: root.setAlias(srcItem.modelData.node_name, srcAliasField.text)
                      }

                      Button {
                        visible: !!srcItem.modelData.alias
                        text: "Reset"
                        implicitWidth: Style.space(64)
                        onClicked: root.resetAlias(srcItem.modelData.node_name)
                      }
                    }
                  }
                }
              }
            }
          }

          // Footer Controls
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Button {
              text: "Reset All to Defaults"
              onClicked: root.resetAll()
            }

            Item { Layout.fillWidth: true }

            Button {
              text: "Done (Esc)"
              onClicked: root.dismiss()
            }
          }
        }
      }
    }
  }
}
