.pragma library

// Shared helpers for the three Fresque surfaces. The tables here mirror
// bin/fresque on purpose: the bar pill has to render before any process has
// run, and the ids are the contract between the script and the interface.

// `themes` is what a source can actually serve. `any` means the source cannot
// be filtered at all: Bing is one picture chosen by someone else each day, so
// it is only used when no theme filter is set, rather than being allowed to
// slip a landscape into a request for animals or space.
var SOURCES = [
  { id: "bing",      label: "Bing",      themes: ["any"] },
  { id: "wikimedia", label: "Wikimedia", themes: ["nature", "space", "architecture", "animals"] },
  { id: "esa",       label: "ESA/Hubble", themes: ["space"] },
  { id: "konachan",  label: "Konachan",  themes: ["anime"] },
  { id: "yandere",   label: "Yande.re",  themes: ["anime"] },
  { id: "picsum",    label: "Unsplash",  themes: ["photos"] }
]

var THEMES = [
  { id: "nature" },
  { id: "space" },
  { id: "architecture" },
  { id: "animals" },
  { id: "photos" },
  { id: "anime" }
]

// The intervals the panel offers and the only values bin/fresque accepts. The
// labels are looked up at render time so they follow the system language.
var INTERVAL_MINUTES = [0, 5, 15, 30, 60, 180, 360, 1440]

var DEFAULT_MINUTES = 1440

// Two languages, chosen by the desktop's own locale, so the plugin speaks
// whatever the rest of the session speaks. Anything not translated falls back
// to English rather than showing a key name.
var STRINGS = {
  en: {
    schedule: "Change automatically",
    themes: "Themes",
    sources: "Sources",
    next: "Next wallpaper",
    working: "Searching",
    skip: "Not this one",
    openSource: "See the source",
    favorite: "Add to favorites",
    unfavorite: "Remove from favorites",
    favorites: "Favorites",
    onlyFavorites: "Only favorites",
    noFavorites: "No favorites yet",
    closeHint: "Esc closes, n takes the next one, s skips this one",
    empty: "No wallpaper yet",
    loading: "Loading",
    offline: "No source answered, retrying in 5 minutes",
    offNotice: "Automatic change is off",
    soon: "Any moment now",
    inMinutes: "In {n} min",
    inHours: "In {n} h",
    inDays: "In {n} days",
    inOneDay: "In 1 day",
    interval_0: "Off",
    interval_5: "5 min",
    interval_15: "15 min",
    interval_30: "30 min",
    interval_60: "1 h",
    interval_180: "3 h",
    interval_360: "6 h",
    interval_1440: "1 day",
    theme_nature: "Nature",
    theme_space: "Space",
    theme_architecture: "Architecture",
    theme_animals: "Animals",
    theme_photos: "Photos",
    theme_anime: "Anime",
    anyTheme: "any theme"
  },
  fr: {
    schedule: "Changement automatique",
    themes: "Thèmes",
    sources: "Sources",
    next: "Fond suivant",
    working: "Recherche",
    skip: "Pas celui-ci",
    openSource: "Voir la source",
    favorite: "Ajouter aux favoris",
    unfavorite: "Retirer des favoris",
    favorites: "Favoris",
    onlyFavorites: "Favoris uniquement",
    noFavorites: "Aucun favori pour l'instant",
    closeHint: "Échap ferme, n suivant, s pas celui-ci",
    empty: "Pas encore de fond d'écran",
    loading: "Chargement",
    offline: "Aucune source n'a répondu, nouvel essai dans 5 minutes",
    offNotice: "Le changement automatique est désactivé",
    soon: "D'un instant à l'autre",
    inMinutes: "Dans {n} min",
    inHours: "Dans {n} h",
    inDays: "Dans {n} jours",
    inOneDay: "Dans 1 jour",
    interval_0: "Désactivé",
    interval_5: "5 min",
    interval_15: "15 min",
    interval_30: "30 min",
    interval_60: "1 h",
    interval_180: "3 h",
    interval_360: "6 h",
    interval_1440: "1 jour",
    theme_nature: "Nature",
    theme_space: "Espace",
    theme_architecture: "Architecture",
    theme_animals: "Animaux",
    theme_photos: "Photos",
    theme_anime: "Anime",
    anyTheme: "tous les thèmes"
  }
}

function localeKey() {
  try {
    var name = Qt.locale().name.toLowerCase()
    return name.indexOf("fr") === 0 ? "fr" : "en"
  } catch (error) {
    return "en"
  }
}

function t(key, values) {
  var table = STRINGS[localeKey()] || STRINGS.en
  var text = table[key]
  if (text === undefined) text = STRINGS.en[key]
  if (text === undefined) return key
  if (values) {
    for (var k in values) text = text.split("{" + k + "}").join(String(values[k]))
  }
  return text
}

// Process output and config files are untrusted input as far as a long lived
// shell process is concerned: a wedged curl or a half written file must not be
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
  return flat.length > limit ? flat.slice(0, limit - 1) + "..." : flat
}

function sourceLabel(id) {
  for (var i = 0; i < SOURCES.length; i++)
    if (SOURCES[i].id === id) return SOURCES[i].label
  return id === "" ? "" : id
}

function themeLabel(id) {
  if (id === "any") return t("anyTheme")
  for (var i = 0; i < THEMES.length; i++)
    if (THEMES[i].id === id) return t("theme_" + THEMES[i].id)
  return ""
}

function intervalLabel(minutes) {
  var m = Number(minutes) || 0
  return t("interval_" + m)
}

function isKnownInterval(minutes) {
  for (var i = 0; i < INTERVAL_MINUTES.length; i++)
    if (INTERVAL_MINUTES[i] === Number(minutes)) return true
  return false
}

function countOn(map) {
  var n = 0
  for (var key in map) if (map[key] === true) n++
  return n
}

// True when at least one theme this source can serve is switched on, which is
// the same rule bin/fresque applies before it asks a source for anything. A
// source marked `any` cannot be filtered, so it only counts when every theme is
// on, that is, when nothing is filtered at all.
function sourceMatches(sourceId, themesMap) {
  for (var i = 0; i < SOURCES.length; i++) {
    if (SOURCES[i].id !== sourceId) continue
    var served = SOURCES[i].themes
    if (served.length === 1 && served[0] === "any") return countOn(themesMap) === THEMES.length
    for (var j = 0; j < served.length; j++)
      if (themesMap && themesMap[served[j]] === true) return true
    return false
  }
  return true
}

function formatSize(width, height) {
  var w = Number(width) || 0
  var h = Number(height) || 0
  return w > 0 && h > 0 ? w + "x" + h : ""
}

// Human countdown to the next change. Kept here rather than in the panel so
// the bar tooltip and the panel header cannot disagree.
function dueLabel(appliedAt, retryAt, minutes, includePrefix) {
  if (!(minutes > 0)) return t("offNotice")
  var interval = minutes * 60000
  var applied = Number(appliedAt) || 0
  var retry = Number(retryAt) || 0
  var due = applied > 0 ? applied + interval : 0
  if (retry > due) due = retry
  if (!(due > 0)) return t("soon")
  var left = due - Date.now()
  if (left <= 0) return t("soon")
  var mins = Math.round(left / 60000)
  if (mins < 1) return t("soon")
  if (mins < 60) return t("inMinutes", { n: mins })
  var hours = Math.floor(mins / 60)
  if (hours < 24) return t("inHours", { n: hours })
  var days = Math.round(hours / 24)
  return days <= 1 ? t("inOneDay") : t("inDays", { n: days })
}

function barTooltip(state) {
  var lines = []
  lines.push(state && state.source
    ? "Fresque, " + sourceLabel(state.source) + (state.resolution ? ", " + state.resolution : "")
    : "Fresque")
  if (state && state.credit) lines.push(singleLine(state.credit, 90))
  lines.push(dueLabel(state ? state.appliedAt : 0, state ? state.retryAt : 0, state ? state.rotateMinutes : 0))
  lines.push(t("closeHint"))
  return lines.join("\n")
}

// A link from a remote source is only ever handed to the browser when it is
// https. Anything else is dropped instead of passed along.
function safeLink(url) {
  if (typeof url !== "string") return ""
  return url.indexOf("https://") === 0 ? url : ""
}
