import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// The Fresque popup: what is on screen right now, how often it changes, and
// which sources feed it.
//
// The whole surface is three controls wide on purpose. Everything that needed
// a setting — a search box, a category bitfield, a resolution filter — is
// decided by the sources instead, so nothing here has to be understood before
// the plugin can be used.
Panel {
  id: root
  moduleName: "mitch.fresque"
  ipcTarget: "mitch.fresque"
  manageIpc: false

  readonly property string cliPath: Qt.resolvedUrl("bin/fresque").toString().replace(/^file:\/\//, "")
  readonly property string home: Quickshell.env("HOME")

  property var anchorItem: null
  property var hostWidget: null

  // The bar tracks the widget mounted in its slot — BarWidget.qml — not this
  // nested panel: the popout coordinator compares against `slot.activeItem`
  // and switchPanelFrom looks the slot up the same way.
  readonly property var barIdentity: hostWidget || root

  property var config: ({})
  property var current: ({})
  property bool working: false
  property string notice: ""

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property int rotateMinutes: {
    var m = Number(config.rotateMinutes)
    return isFinite(m) && m > 0 ? Math.round(m) : 0
  }
  readonly property var enabledSources: {
    var map = {}
    for (var i = 0; i < Model.SOURCES.length; i++) {
      var id = Model.SOURCES[i].id
      map[id] = (config.sources && config.sources[id]) === true
    }
    return map
  }
  readonly property string sourceLabel: Model.sourceLabel(current.source || "")
  readonly property string creditText: Model.singleLine(current.credit || "", 120)
  readonly property string dueText: Model.dueLabel(current.appliedAt, current.retryAt, rotateMinutes)

  function open() {
    root.reload()
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function closeForPopoutSwitch() {
    root.controller.hide()
  }

  function reload() {
    configView.reload()
    currentView.reload()
  }

  function applyConfig(raw) {
    config = Model.parseJson(raw, {}, 65536)
  }

  function applyCurrent(raw) {
    current = Model.parseJson(raw, {}, 262144)
  }

  // Interval and source changes are written through the CLI, so the script
  // stays the single owner of the config format and validates every value.
  function setInterval(minutes) {
    if (!Model.isKnownInterval(minutes)) return
    configProcess.command = [root.cliPath, "config", "set", "rotateMinutes", String(minutes)]
    configProcess.running = true
  }

  function toggleSource(id) {
    var next = enabledSources[id] === true ? "false" : "true"
    configProcess.command = [root.cliPath, "config", "set", "sources." + id, next]
    configProcess.running = true
  }

  function nextWallpaper() {
    if (working) return
    working = true
    notice = "Recherche d'un fond…"
    nextProcess.command = [root.cliPath, "next"]
    nextProcess.running = true
  }

  function openSource() {
    var url = Model.safeLink(current.link || "")
    if (url === "" || !bar) return
    // shellQuote, so a link that carries shell characters is a data argument
    // and never part of the command.
    bar.run("xdg-open " + bar.shellQuote(url))
  }

  FileView {
    id: configView
    path: root.home + "/.config/omarchy/fresque.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.applyConfig(text())
    onFileChanged: reload()
    onLoadFailed: root.applyConfig("{}")
  }

  FileView {
    id: currentView
    path: root.home + "/.local/state/fresque/current.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.applyCurrent(text())
    onFileChanged: reload()
    onLoadFailed: root.applyCurrent("{}")
  }

  // Only exists to refresh the countdown while the panel stays open.
  Timer {
    id: dueUpdate
    interval: 30000
    repeat: true
    running: root.opened
    onTriggered: root.current = JSON.parse(JSON.stringify(root.current))
  }

  Process {
    id: configProcess
    command: []
    // The FileView watch picks the new value up; the reload only makes the
    // change land even if the write kept the file's modification time.
    onExited: root.reload()
  }

  Process {
    id: nextProcess
    command: []
    stdout: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      root.working = false
      root.notice = exitCode === 0 ? "" : "Aucune source n'a répondu — nouvel essai dans 5 min"
      root.reload()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.nextWallpaper()
      onTextKey: function(t) {
        if (t === "n" || t === "N") root.nextWallpaper()
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(14)

        // ---- What is on screen. The file is already decoded by the
        //      background service, so this costs nothing extra; sourceSize
        //      keeps a 4K original from being held at full size by the pill.
        Rectangle {
          width: parent.width
          height: width * 9 / 16
          color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.07)
          clip: true
          radius: Style.space(6)

          Image {
            id: hero
            anchors.fill: parent
            source: root.current.path ? "file://" + root.current.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Math.round(width)
            sourceSize.height: Math.round(height)
            visible: status === Image.Ready
          }

          Text {
            anchors.centerIn: parent
            visible: hero.status !== Image.Ready
            text: root.working ? "Chargement…" : "Aucun fond pour l'instant"
            color: root.contentForeground
            opacity: 0.6
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        // ---- Attribution. Every source carries a credit and a licence, and
        //      a wallpaper plugin that hides them is not a good citizen.
        Column {
          width: parent.width
          spacing: Style.space(3)

          Row {
            width: parent.width
            spacing: Style.space(8)

            Text {
              text: root.sourceLabel
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: root.current.resolution || ""
              visible: text !== ""
              color: root.contentForeground
              opacity: 0.55
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Text {
            width: parent.width
            text: root.creditText
            visible: text !== ""
            color: root.contentForeground
            opacity: 0.6
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            width: parent.width
            text: root.notice !== "" ? root.notice : root.dueText
            color: root.notice !== ""
              ? Style.hoverStateColor(root.contentForeground, Color.accent)
              : root.contentForeground
            opacity: root.notice !== "" ? 1 : 0.45
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }
        }

        // ---- Rotation. Eight choices, one row, the default already active.
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "Changement automatique"
            color: root.contentForeground
            opacity: 0.55
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            id: intervalRow
            spacing: Style.space(4)

            Repeater {
              model: Model.INTERVALS

              Rectangle {
                required property var modelData
                readonly property bool active: root.rotateMinutes === modelData.minutes

                width: intervalLabel.implicitWidth + Style.space(14)
                height: Style.space(24)
                radius: Style.space(4)
                color: active
                  ? Style.hoverFillFor(root.contentForeground, Color.accent)
                  : (intervalMouse.containsMouse ? Style.hoverFillFor(root.contentForeground, Color.accent) : "transparent")
                border.width: 1
                border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, active ? 0.5 : 0.18)

                Text {
                  id: intervalLabel
                  anchors.centerIn: parent
                  text: modelData.label
                  color: active
                    ? Style.selectedStateColor(root.contentForeground, Color.accent)
                    : root.contentForeground
                  opacity: active ? 1 : 0.75
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                }

                MouseArea {
                  id: intervalMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.setInterval(modelData.minutes)
                }
              }
            }
          }
        }

        // ---- Sources. Turning one off is a preference, not a requirement;
        //      all four are on out of the box.
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "Sources"
            color: root.contentForeground
            opacity: 0.55
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            spacing: Style.space(4)

            Repeater {
              model: Model.SOURCES

              Rectangle {
                required property var modelData
                readonly property bool active: root.enabledSources[modelData.id] === true

                width: sourceLabelText.implicitWidth + Style.space(14)
                height: Style.space(24)
                radius: Style.space(4)
                color: active
                  ? Style.hoverFillFor(root.contentForeground, Color.accent)
                  : "transparent"
                border.width: 1
                border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, active ? 0.5 : 0.18)

                Text {
                  id: sourceLabelText
                  anchors.centerIn: parent
                  text: modelData.label
                  color: active
                    ? Style.selectedStateColor(root.contentForeground, Color.accent)
                    : root.contentForeground
                  opacity: active ? 1 : 0.5
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleSource(modelData.id)
                }
              }
            }
          }

          Text {
            width: parent.width
            text: root.enabledSources[root.current.source] !== undefined && root.current.source !== ""
              ? Model.sourceNote(root.current.source)
              : ""
            visible: text !== ""
            color: root.contentForeground
            opacity: 0.4
            elide: Text.ElideRight
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }
        }

        // ---- The two actions worth a button. Everything else is a
        //      reference, not a decision.
        Row {
          width: parent.width
          spacing: Style.space(8)

          Rectangle {
            id: nextButton
            width: nextLabel.implicitWidth + Style.space(24)
            height: Style.space(30)
            radius: Style.space(5)
            color: nextMouse.containsMouse
              ? Style.hoverFillFor(root.contentForeground, Color.accent)
              : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.1)
            border.width: 1
            border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.35)

            Text {
              id: nextLabel
              anchors.centerIn: parent
              text: root.working ? "Recherche…" : "Fond suivant"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            MouseArea {
              id: nextMouse
              anchors.fill: parent
              hoverEnabled: true
              enabled: !root.working
              cursorShape: Qt.PointingHandCursor
              onClicked: root.nextWallpaper()
            }
          }

          Rectangle {
            width: sourceButtonLabel.implicitWidth + Style.space(20)
            height: Style.space(30)
            radius: Style.space(5)
            visible: Model.safeLink(root.current.link || "") !== ""
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.2)

            Text {
              id: sourceButtonLabel
              anchors.centerIn: parent
              text: "Voir la source"
              color: root.contentForeground
              opacity: sourceMouse.containsMouse ? 1 : 0.7
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }

            MouseArea {
              id: sourceMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openSource()
            }
          }
        }

        // ---- Reference line: where the images live, and the one shortcut.
        Text {
          width: parent.width
          text: "Échap : fermer · n : fond suivant"
          color: root.contentForeground
          opacity: 0.35
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
