import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Bar entry point.
//
// It paints one glyph and owns nothing else: the config file and the state file
// the script writes are its only inputs, so the pill, the panel and the
// rotation service never have to talk to each other.
//
// Left click opens the panel, right click takes the next wallpaper, which is
// the whole feature set most people ever touch.
BarWidget {
  id: root
  moduleName: "io.github.shika34.fresque"

  readonly property string cliPath: Qt.resolvedUrl("bin/fresque").toString().replace(/^file:\/\//, "")
  readonly property string home: Quickshell.env("HOME")

  property var config: ({})
  property var current: ({})
  property bool working: false

  readonly property int rotateMinutes: {
    var m = Number(config.rotateMinutes)
    return isFinite(m) && m > 0 ? Math.round(m) : 0
  }
  readonly property bool rotating: rotateMinutes > 0
  property string langStamp: Model.localeKey()
  readonly property string tooltipText: Model.barTooltip({
    lang: langStamp,
    source: current.source,
    resolution: Model.formatSize(current.width, current.height),
    credit: current.credit,
    appliedAt: current.appliedAt,
    retryAt: current.retryAt,
    rotateMinutes: rotateMinutes
  })

  function applyConfig(raw) {
    config = Model.parseJson(raw, {}, 65536)
    Model.setLanguage(config.language || "auto")
  }

  function applyCurrent(raw) {
    current = Model.parseJson(raw, {}, 262144)
  }

  function nextWallpaper() {
    if (working) return
    working = true
    nextProcess.command = [root.cliPath, "next"]
    nextProcess.running = true
  }

  // Panel shape. Bar.findPanelWidget requires open, close and opened on the
  // bar widget root for shell.summon, shell.hide and shell.toggle routing.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  // Rebuilding the panel is how a language change takes effect: every label is
  // a binding evaluated once at creation, so a panel built before the settings
  // were read would keep the previous language for the rest of the session.
  function reloadPanel() {
    var wasOpen = root.opened
    panelLoader.active = false
    panelLoader.active = true
    Qt.callLater(function() {
      root.injectPanel()
      if (wasOpen) root.open()
    })
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  FileView {
    path: root.home + "/.config/omarchy/fresque.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.applyConfig(text())
    onFileChanged: reload()
    onLoadFailed: root.applyConfig("{}")
  }

  FileView {
    path: root.home + "/.local/state/fresque/current.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.applyCurrent(text())
    onFileChanged: reload()
    onLoadFailed: root.applyCurrent("{}")
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  // The IPC surface lives on the panel, not here: the panel owns the plugin's
  // command target the same way omarchy.weather does, and a handler on the bar
  // widget would only ever be shadowed by it.
  Process {
    id: nextProcess
    command: []
    stdout: StdioCollector { waitForEnd: true }
    onExited: root.working = false
  }

  // One glyph carries the plugin's identity, a wallpaper, and the bar's own
  // vocabulary carries the state: dimmed while a picture is being fetched, and
  // dimmed when the rotation is paused. The colour is left alone, so the mark
  // is the same colour as every other icon in the bar, which is what keeps it
  // readable over a light wallpaper. Tinting it with the theme accent, however
  // pretty on a dark desktop, made it vanish on a pale one.
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰋩" // nf-md-wallpaper
    dimmed: root.working || !root.rotating
    tooltipText: root.tooltipText
    horizontalMargin: 8.75
    verticalPadding: 8.75

    // Left click opens the panel, right click takes the next wallpaper.
    onPressed: function(b) {
      if (b === Qt.RightButton) root.nextWallpaper()
      else root.togglePanel()
    }
  }
}
