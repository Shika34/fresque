.pragma library

// Pure data shaping shared by the three Fresque surfaces. The source list is
// mirrored from bin/fresque on purpose: the bar pill must be able to render
// before any process has run, and the ids are the contract between the script
// and the UI.

var SOURCES = [
  { id: "wallhaven", label: "Wallhaven",  note: "Le top du mois, 4K+, catégorie générale" },
  { id: "bing",      label: "Bing",       note: "L'image du jour, photographie professionnelle" },
  { id: "wikimedia", label: "Wikimedia",  note: "Images remarquables, licence libre" },
  { id: "picsum",    label: "Unsplash",   note: "Photographies Unsplash, sélection fixe" }
]

// The intervals the panel offers, and the only values bin/fresque accepts.
var INTERVALS = [
  { label: "Off",   minutes: 0 },
  { label: "5 min", minutes: 5 },
  { label: "15 min", minutes: 15 },
  { label: "30 min", minutes: 30 },
  { label: "1 h",   minutes: 60 },
  { label: "3 h",   minutes: 180 },
  { label: "6 h",   minutes: 360 },
  { label: "Jour",  minutes: 1440 }
]

var DEFAULT_MINUTES = 1440

// Process output and config files are untrusted input as far as a long-lived
// shell process is concerned: a wedged curl or a half-written file must not be
// able to blow up the parse.
function parseJson(raw, fallback, limit) {
  try {
    if (typeof raw !== "string") return fallback
    if (raw.length > (limit || 262144)) return fallback
    var trimmed = raw.trim()
    if (trimmed === "") return fallback
    var parsed = JSON.parse(trimmed)
    return parsed === null || parsed === undefined ? fallback : parsed
  } catch (error) {
    return fallback
  }
}

function singleLine(value, max) {
  if (typeof value !== "string") return ""
  var flat = value.replace(/\s+/g, " ").trim()
  var limit = max || 200
  return flat.length > limit ? flat.slice(0, limit - 1) + "…" : flat
}

function sourceLabel(id) {
  for (var i = 0; i < SOURCES.length; i++)
    if (SOURCES[i].id === id) return SOURCES[i].label
  return id === "" ? "—" : id
}

function sourceNote(id) {
  for (var i = 0; i < SOURCES.length; i++)
    if (SOURCES[i].id === id) return SOURCES[i].note
  return ""
}

function intervalLabel(minutes) {
  for (var i = 0; i < INTERVALS.length; i++)
    if (INTERVALS[i].minutes === minutes) return INTERVALS[i].label
  return minutes + " min"
}

function isKnownInterval(minutes) {
  for (var i = 0; i < INTERVALS.length; i++)
    if (INTERVALS[i].minutes === minutes) return true
  return false
}

function countEnabled(sources) {
  var n = 0
  for (var i = 0; i < SOURCES.length; i++)
    if (sources && sources[SOURCES[i].id] === true) n++
  return n
}

// Human countdown to the next rotation. Kept here rather than in the panel so
// the bar tooltip and the panel header cannot disagree.
function dueLabel(appliedAt, retryAt, minutes) {
  if (!(minutes > 0)) return "Changement automatique désactivé"
  var interval = minutes * 60000
  var applied = Number(appliedAt) || 0
  var retry = Number(retryAt) || 0
  var due = applied > 0 ? applied + interval : 0
  if (retry > due) due = retry
  if (!(due > 0)) return "Bientôt"
  var left = due - Date.now()
  if (left <= 0) return "Bientôt"
  var mins = Math.round(left / 60000)
  if (mins < 1) return "Dans moins d'une minute"
  if (mins < 60) return "Dans " + mins + " min"
  var hours = Math.floor(mins / 60)
  if (hours < 24) return "Dans " + hours + " h" + (mins % 60 > 5 ? " " + (mins % 60) : "")
  return "Dans " + Math.round(hours / 24) + " j"
}

function barTooltip(state) {
  var lines = []
  lines.push(state && state.source
    ? "Fresque · " + sourceLabel(state.source) + (state.resolution ? " · " + state.resolution : "")
    : "Fresque")
  if (state && state.credit) lines.push(singleLine(state.credit, 90))
  lines.push(dueLabel(state ? state.appliedAt : 0, state ? state.retryAt : 0, state ? state.rotateMinutes : 0))
  lines.push("Clic : panneau · Clic droit : suivant")
  return lines.join("\n")
}

// A link from a remote source is only ever handed to the browser when it is
// https. Anything else is dropped rather than passed along.
function safeLink(url) {
  if (typeof url !== "string") return ""
  return url.indexOf("https://") === 0 ? url : ""
}
