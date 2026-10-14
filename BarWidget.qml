import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Bar entry point.
//
// It renders one glyph and owns nothing else: the config file and the state
// file the CLI writes are its only inputs, so the pill, the panel and the
// rotation service never have to talk to each other.
//
// Left click opens the panel, right click pulls the next wallpaper — the one
// gesture people ask for without wanting to open anything.
BarWidget {
  id: root
  moduleName: "mitch.fresque"

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
  readonly property string tooltipText: Model.barTooltip({
    source: current.source,
    resolution: current.resolution,
    credit: current.credit,
    appliedAt: current.appliedAt,
    retryAt: current.retryAt,
    rotateMinutes: rotateMinutes
  })

  function applyConfig(raw) {
    config = Model.parseJson(raw, {}, 65536)
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

  // ---- Panel shape. Bar.findPanelWidget requires open/close/opened on the
  //      bar-widget root for shell.summon/hide/toggle routing.
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

  // The IPC surface (open/close/toggle/next) lives on the panel, not here:
  // the panel owns the id's command target the same way omarchy.weather does,
  // and a handler on the bar widget would only ever be shadowed by it.
  Process {
    id: nextProcess
    command: []
    stdout: StdioCollector { waitForEnd: true }
    onExited: root.working = false
  }

  // A single glyph, so a content-width slot is right: BarIconButton would pin
  // it to an icon slot and anything longer would overflow its neighbours.
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.working ? "󰒓" : (root.rotating ? "󰑖" : "󰋩")
    tooltipText: root.tooltipText
    horizontalMargin: 8.75
    verticalPadding: 8.75
    opacity: root.working ? 0.55 : 1

    onPressed: function(b) {
      if (b === Qt.RightButton) root.nextWallpaper()
      else root.togglePanel()
    }

    Behavior on opacity { NumberAnimation { duration: 140 } }
  }
}
