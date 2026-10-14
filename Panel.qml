import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// The Fresque popup: what is on screen, how often it changes, what it is
// allowed to be, and what the user has decided to keep.
//
// Everything is centred, because the panel is a small piece of furniture on a
// large screen and a left aligned column of chips reads as a form to fill in.
Panel {
  id: root
  moduleName: "mitch.fresque"
  ipcTarget: "mitch.fresque"
  manageIpc: false

  readonly property string cliPath: Qt.resolvedUrl("bin/fresque").toString().replace(/^file:\/\//, "")
  readonly property string home: Quickshell.env("HOME")

  property var anchorItem: null
  property var hostWidget: null

  // The bar tracks the widget mounted in its slot, BarWidget.qml, not this
  // nested panel: the popout coordinator compares against slot.activeItem and
  // switchPanelFrom looks the slot up the same way.
  readonly property var barIdentity: hostWidget || root

  property var config: ({})
  property var current: ({})
  property var info: ({})
  property bool working: false
  property string notice: ""

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property int rotateMinutes: {
    var m = Number(config.rotateMinutes)
    return isFinite(m) && m > 0 ? Math.round(m) : 0
  }
  readonly property var themesMap: config.themes ? config.themes : ({})
  readonly property var sourcesMap: config.sources ? config.sources : ({})
  readonly property bool favoritesOnly: info.favoritesOnly === true || config.favoritesOnly === true
  readonly property bool isFavorite: info.isFavorite === true
  readonly property int favoriteCount: Number(info.favorites) || 0
  readonly property string sourceName: Model.sourceLabel(current.source || "")
  readonly property string creditText: Model.singleLine(current.credit || "", 120)
  readonly property string resolutionText: Model.formatSize(current.width, current.height)
  readonly property string dueText: Model.dueLabel(current.appliedAt, current.retryAt, rotateMinutes)
  readonly property string favoritesLabel: Model.t("favorites") + (favoriteCount > 0 ? " (" + favoriteCount + ")" : "")

  function open() {
    root.reload()
    root.runStatus()
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

  // `fresque status` reads files only, no network: it is the cheap way to learn
  // how many favourites exist and whether the one on screen is one of them.
  function runStatus() {
    if (statusProcess.running) return
    statusProcess.command = [root.cliPath, "status"]
    statusProcess.running = true
  }

  function applyStatus(raw) {
    info = Model.parseJson(raw, {}, 262144)
  }

  // Every change goes through the script, so it stays the only owner of the
  // config format and of what counts as a valid value.
  function setInterval(minutes) {
    if (!Model.isKnownInterval(minutes)) return
    runConfig("rotateMinutes", String(minutes))
  }

  function toggleTheme(id) {
    runConfig("themes." + id, themesMap[id] === true ? "false" : "true")
  }

  function toggleSource(id) {
    runConfig("sources." + id, sourcesMap[id] === true ? "false" : "true")
  }

  function toggleFavoritesOnly() {
    runConfig("favoritesOnly", favoritesOnly ? "false" : "true")
  }

  function runConfig(key, value) {
    configProcess.command = [root.cliPath, "config", "set", key, value]
    configProcess.running = true
  }

  function runAction(name) {
    if (working) return
    working = true
    notice = Model.t("working") + "..."
    actionProcess.command = [root.cliPath, name]
    actionProcess.running = true
  }

  function nextWallpaper() {
    runAction("next")
  }

  // The one gesture that teaches the rotation something: the picture on screen
  // is blocked and replaced, so it never comes back.
  function skipWallpaper() {
    runAction("skip")
  }

  // Favourites are moved, not copied: one file, one place, and the pruning
  // code never looks in that folder.
  function toggleFavorite() {
    runAction(isFavorite ? "unfavorite" : "favorite")
  }

  function openSource() {
    var url = Model.safeLink(current.link || "")
    if (url === "" || !bar) return
    // shellQuote keeps a link with shell characters a data argument rather
    // than a piece of the command.
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

  // Keeps the countdown honest while the panel stays open.
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
    onExited: {
      root.reload()
      root.runStatus()
    }
  }

  Process {
    id: statusProcess
    command: []
    stdout: StdioCollector { waitForEnd: true }
    onExited: root.applyStatus(stdout.text)
  }

  Process {
    id: actionProcess
    command: []
    stdout: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      root.working = false
      root.notice = exitCode === 0 ? "" : Model.t(root.favoritesOnly ? "noFavorites" : "offline")
      root.reload()
      root.runStatus()
    }
  }

  // The panel owns the command target: `omarchy-shell mitch.fresque next`
  // lands here even though the bar pill is what people click.
  IpcHandler {
    target: root.ipcTarget

    function next(): void { root.nextWallpaper() }
    function skip(): void { root.skipWallpaper() }
    function favorite(): void { root.toggleFavorite() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(580))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.nextWallpaper()
      onTextKey: function(t) {
        if (t === "n" || t === "N") root.nextWallpaper()
        else if (t === "s" || t === "S") root.skipWallpaper()
        else if (t === "f" || t === "F") root.toggleFavorite()
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(14)

        // ---- What is on screen. The file is already decoded by the
        //      background service, and sourceSize keeps a 4K original from
        //      being held at full size by the popup.
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
          }

          Text {
            anchors.centerIn: parent
            visible: hero.status !== Image.Ready
            text: root.working ? Model.t("loading") + "..." : Model.t("empty")
            color: root.contentForeground
            opacity: 0.6
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        // ---- Credit. Every source carries an author and a licence, and a
        //      wallpaper plugin that hides them is not a good guest.
        Column {
          width: parent.width
          spacing: Style.space(3)

          Row {
            spacing: Style.space(8)
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
              text: root.sourceName
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: root.resolutionText
              visible: text !== ""
              color: root.contentForeground
              opacity: 0.55
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: Model.themeLabel(root.current.theme || "")
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
            horizontalAlignment: Text.AlignHCenter
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
            horizontalAlignment: Text.AlignHCenter
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }
        }

        // ---- Change automatically. The default is already the first choice
        //      most people would pick.
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            width: parent.width
            text: Model.t("schedule")
            color: root.contentForeground
            opacity: 0.55
            horizontalAlignment: Text.AlignHCenter
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            spacing: Style.space(4)
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
              model: Model.INTERVAL_MINUTES

              Rectangle {
                required property int modelData
                readonly property bool active: root.rotateMinutes === modelData

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
                  text: Model.intervalLabel(modelData)
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
                  onClicked: root.setInterval(modelData)
                }
              }
            }
          }
        }

        // ---- Themes. This is the preference filter: a theme that is off is
        //      never queried, so nothing from it can reach the screen.
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            width: parent.width
            text: Model.t("themes")
            color: root.contentForeground
            opacity: 0.55
            horizontalAlignment: Text.AlignHCenter
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            spacing: Style.space(4)
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
              model: Model.THEMES

              Rectangle {
                required property var modelData
                readonly property bool active: root.themesMap[modelData.id] === true

                width: themeLabelText.implicitWidth + Style.space(14)
                height: Style.space(24)
                radius: Style.space(4)
                color: active
                  ? Style.hoverFillFor(root.contentForeground, Color.accent)
                  : (themeMouse.containsMouse ? Style.hoverFillFor(root.contentForeground, Color.accent) : "transparent")
                border.width: 1
                border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, active ? 0.5 : 0.18)

                Text {
                  id: themeLabelText
                  anchors.centerIn: parent
                  text: Model.themeLabel(modelData.id)
                  color: active
                    ? Style.selectedStateColor(root.contentForeground, Color.accent)
                    : root.contentForeground
                  opacity: active ? 1 : 0.5
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                }

                MouseArea {
                  id: themeMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleTheme(modelData.id)
                }
              }
            }
          }
        }

        // ---- Sources. A source that cannot serve any chosen theme is dimmed
        //      rather than hidden, so it is obvious why it stays quiet.
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            width: parent.width
            text: Model.t("sources")
            color: root.contentForeground
            opacity: 0.55
            horizontalAlignment: Text.AlignHCenter
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            spacing: Style.space(4)
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
              model: Model.SOURCES

              Rectangle {
                required property var modelData
                readonly property bool on: root.sourcesMap[modelData.id] === true
                readonly property bool usable: Model.sourceMatches(modelData.id, root.themesMap)

                width: sourceLabelText.implicitWidth + Style.space(14)
                height: Style.space(24)
                radius: Style.space(4)
                color: on && usable
                  ? Style.hoverFillFor(root.contentForeground, Color.accent)
                  : (sourceChipMouse.containsMouse ? Style.hoverFillFor(root.contentForeground, Color.accent) : "transparent")
                border.width: 1
                border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, on && usable ? 0.5 : 0.15)

                Text {
                  id: sourceLabelText
                  anchors.centerIn: parent
                  text: modelData.label
                  color: on && usable
                    ? Style.selectedStateColor(root.contentForeground, Color.accent)
                    : root.contentForeground
                  opacity: on ? (usable ? 1 : 0.35) : 0.5
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                }

                MouseArea {
                  id: sourceChipMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleSource(modelData.id)
                }
              }
            }
          }
        }

        // ---- Favorites. One switch: either the rotation draws from the whole
        //      world, or only from what has been kept.
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            width: parent.width
            text: root.favoritesLabel
            color: root.contentForeground
            opacity: 0.55
            horizontalAlignment: Text.AlignHCenter
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            spacing: Style.space(4)
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
              width: onlyFavoritesLabel.implicitWidth + Style.space(14)
              height: Style.space(24)
              radius: Style.space(4)
              color: root.favoritesOnly
                ? Style.hoverFillFor(root.contentForeground, Color.accent)
                : (onlyFavoritesMouse.containsMouse ? Style.hoverFillFor(root.contentForeground, Color.accent) : "transparent")
              border.width: 1
              border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, root.favoritesOnly ? 0.5 : 0.18)

              Text {
                id: onlyFavoritesLabel
                anchors.centerIn: parent
                text: Model.t("onlyFavorites")
                color: root.favoritesOnly
                  ? Style.selectedStateColor(root.contentForeground, Color.accent)
                  : root.contentForeground
                opacity: root.favoritesOnly ? 1 : 0.7
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.bodySmall
              }

              MouseArea {
                id: onlyFavoritesMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleFavoritesOnly()
              }
            }
          }
        }

        // ---- The actions. Everything above is a reference; these four are the
        //      ones that do something.
        Row {
          spacing: Style.space(8)
          anchors.horizontalCenter: parent.horizontalCenter

          Rectangle {
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
              text: root.working ? Model.t("working") + "..." : Model.t("next")
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
            width: skipLabel.implicitWidth + Style.space(20)
            height: Style.space(30)
            radius: Style.space(5)
            color: skipMouse.containsMouse
              ? Style.hoverFillFor(root.contentForeground, Color.accent)
              : "transparent"
            border.width: 1
            border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.25)

            Text {
              id: skipLabel
              anchors.centerIn: parent
              text: Model.t("skip")
              color: root.contentForeground
              opacity: 0.8
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }

            MouseArea {
              id: skipMouse
              anchors.fill: parent
              hoverEnabled: true
              enabled: !root.working
              cursorShape: Qt.PointingHandCursor
              onClicked: root.skipWallpaper()
            }
          }

          Rectangle {
            width: favoriteLabel.implicitWidth + Style.space(20)
            height: Style.space(30)
            radius: Style.space(5)
            color: favoriteMouse.containsMouse
              ? Style.hoverFillFor(root.contentForeground, Color.accent)
              : "transparent"
            border.width: 1
            border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, root.isFavorite ? 0.5 : 0.25)

            Text {
              id: favoriteLabel
              anchors.centerIn: parent
              text: root.isFavorite ? Model.t("unfavorite") : Model.t("favorite")
              color: root.isFavorite
                ? Style.selectedStateColor(root.contentForeground, Color.accent)
                : root.contentForeground
              opacity: 0.85
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }

            MouseArea {
              id: favoriteMouse
              anchors.fill: parent
              hoverEnabled: true
              enabled: !root.working
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleFavorite()
            }
          }

          Rectangle {
            width: sourceButtonLabel.implicitWidth + Style.space(20)
            height: Style.space(30)
            radius: Style.space(5)
            visible: Model.safeLink(root.current.link || "") !== ""
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.25)

            Text {
              id: sourceButtonLabel
              anchors.centerIn: parent
              text: Model.t("openSource")
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

        // ---- One line of reference, then nothing.
        Text {
          width: parent.width
          text: Model.t("closeHint")
          color: root.contentForeground
          opacity: 0.35
          horizontalAlignment: Text.AlignHCenter
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
