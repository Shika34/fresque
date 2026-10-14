import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// Headless rotation timer.
//
// It owns no UI and no state of its own: the config file is the input, the CLI
// is the output, and the timestamps the CLI writes are the clock. That keeps
// the three surfaces decoupled — the shell injects `settings` into bar widgets
// only, so a service that depended on injected config could not see it.
Item {
  id: root

  // Injected by omarchy-shell's service loader.
  property var shell: null
  property var manifest: null

  readonly property string cliPath: Qt.resolvedUrl("bin/fresque").toString().replace(/^file:\/\//, "")
  readonly property string home: Quickshell.env("HOME")

  // QML's int timer interval tops out around 24 days; clamping keeps a long
  // interval from wrapping into a negative value that never fires.
  readonly property int maxIntervalMs: 2073600000

  property int rotateMinutes: Model.DEFAULT_MINUTES
  property double appliedAt: 0
  property double retryAt: 0
  property bool configLoaded: false
  property bool stateLoaded: false
  // A missing config file is what a fresh install looks like: that is the only
  // case where Fresque installs a first wallpaper by itself. A config that is
  // present — even with rotation off — is a decision, and the service leaves
  // the wallpaper alone.
  property bool freshInstall: false
  property int configLoads: 0
  property string lastConfigRaw: ""

  readonly property double intervalMs: rotateMinutes > 0 ? rotateMinutes * 60000 : 0

  Component.onCompleted: {
    // Reading the config file is what decides whether this is a fresh
    // install, so nothing is scheduled until the views have answered.
    configView.reload()
    stateView.reload()
  }

  function applyConfig(raw) {
    lastConfigRaw = String(raw).slice(0, 200)
    configLoads = configLoads + 1
    var config = Model.parseJson(raw, {}, 65536)
    var minutes = Number(config.rotateMinutes)
    rotateMinutes = isFinite(minutes) && minutes >= 0 ? Math.round(minutes) : Model.DEFAULT_MINUTES
    configLoaded = true
    reschedule()
  }

  function applyState(raw) {
    var state = Model.parseJson(raw, {}, 262144)
    var at = Number(state.appliedAt)
    var retry = Number(state.retryAt)
    appliedAt = isFinite(at) && at > 0 ? at : 0
    retryAt = isFinite(retry) && retry > 0 ? retry : 0
    stateLoaded = true
    reschedule()
  }

  // When the next wallpaper is due. A failed attempt leaves a `retryAt` five
  // minutes ahead, which wins over the interval: an offline laptop should not
  // sit on an empty desktop for a whole day.
  function dueAt() {
    if (intervalMs <= 0) return 0
    var due = appliedAt > 0 ? appliedAt + intervalMs : 0
    if (retryAt > due) due = retryAt
    if (due <= 0) return Date.now() + 60000
    return due
  }

  // Always re-armed to the *remaining* time rather than a fresh full interval:
  // without this, every shell restart (or every plugin file save, which
  // hot-reloads it) would silently postpone the rotation.
  function reschedule() {
    if (!configLoaded || !stateLoaded) return

    if (intervalMs <= 0) {
      rotateTimer.stop()
      return
    }

    var remaining = dueAt() - Date.now()
    if (remaining <= 0) {
      rotate()
      return
    }

    rotateTimer.stop()
    rotateTimer.interval = Math.min(remaining, maxIntervalMs)
    rotateTimer.start()
  }

  function rotate() {
    if (rotateProcess.running || freshInstall) return
    rotateProcess.command = [root.cliPath, "next"]
    rotateProcess.running = true
  }

  function installFirst() {
    if (bootstrapProcess.running) return
    bootstrapProcess.command = [root.cliPath, "init"]
    bootstrapProcess.running = true
  }

  FileView {
    id: configView
    path: root.home + "/.config/omarchy/fresque.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.applyConfig(text())
    onFileChanged: reload()
    onLoadFailed: {
      // No config yet: this is the fresh install the plugin is judged on.
      root.applyConfig(JSON.stringify({ rotateMinutes: Model.DEFAULT_MINUTES }))
      root.freshInstall = true
      root.installFirst()
    }
  }

  FileView {
    id: stateView
    path: root.home + "/.local/state/fresque/current.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.applyState(text())
    onFileChanged: reload()
    onLoadFailed: root.applyState("{}")
  }

  Timer {
    id: rotateTimer
    repeat: false
    onTriggered: root.rotate()
  }

  // Temporary probe: `omarchy-shell fresquedbg dump`.
  IpcHandler {
    target: "fresquedbg"

    function dump(): string {
      return JSON.stringify({
        rotateMinutes: root.rotateMinutes,
        intervalMs: root.intervalMs,
        appliedAt: root.appliedAt,
        retryAt: root.retryAt,
        timerRunning: rotateTimer.running,
        timerInterval: rotateTimer.interval,
        configLoaded: root.configLoaded,
        stateLoaded: root.stateLoaded,
        freshInstall: root.freshInstall,
        configLoads: root.configLoads,
        lastConfigRaw: root.lastConfigRaw,
        now: Date.now()
      })
    }
  }

  Process {
    id: bootstrapProcess
    command: []
    stdout: StdioCollector { waitForEnd: true }
    onExited: {
      root.freshInstall = false
      // The CLI just wrote both files; reading them again is what arms the
      // timer for the first real interval.
      configView.reload()
      stateView.reload()
    }
  }

  Process {
    id: rotateProcess
    command: []
    stdout: StdioCollector { waitForEnd: true }
    onExited: {
      // Success and failure both land in current.json — `appliedAt` on one,
      // `retryAt` on the other — so reloading is all the rescheduling this
      // needs, including the case where the write kept the same mtime.
      stateView.reload()
      configView.reload()
    }
  }
}
