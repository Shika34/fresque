.pragma library

// Shared helpers for the three Fresque surfaces. The tables here mirror
// bin/fresque on purpose: the bar pill has to render before any process has
// run, and the ids are the contract between the script and the interface.

// `themes` is what a source can actually serve. `any` means the source cannot
// be filtered at all: Bing is one picture chosen by someone else each day, so
// it is only used when no theme filter is set, rather than being allowed to
// slip a landscape into a request for animals or space.
var SOURCES = [
  { id: "bing",      label: "Bing",      themes: ["photos"] },
  { id: "wikimedia", label: "Wikimedia", themes: ["nature", "space", "architecture", "animals"] },
  { id: "noirlab",   label: "NOIRLab",   themes: ["space"] },
  { id: "konachan",  label: "Konachan",  themes: ["anime"] },
  { id: "yandere",   label: "Yande.re",  themes: ["anime"] },
  { id: "picsum",    label: "Unsplash",  themes: ["photos"] },
  { id: "omarchy",   label: "Omarchy",   themes: ["photos"] }
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

// The languages the interface speaks. Someone reading this list is looking for
// their own, so it is the ten most spoken languages in the world plus the three
// that matter most on a Linux desktop after those.
var LANGUAGE_CODES = ["en", "zh", "hi", "es", "fr", "ar", "pt", "ru", "ja", "de", "it", "ko", "tr"]

// Two letter codes Qt hands back that are worth folding into one translation.
var LOCALE_ALIASES = {
  zh: "zh", "zh-cn": "zh", "zh-tw": "zh", "zh-hans": "zh", "zh-hant": "zh",
  pt: "pt", "pt-br": "pt", "pt-pt": "pt",
  es: "es", "es-es": "es", "es-mx": "es", "es-ar": "es",
  ar: "ar", "ar-eg": "ar", "ar-sa": "ar", "ar-ma": "ar", "ar-dz": "ar",
  de: "de", "de-de": "de", "de-at": "de", "de-ch": "de",
  fr: "fr", "fr-fr": "fr", "fr-ca": "fr", "fr-be": "fr",
  en: "en", "en-us": "en", "en-gb": "en", "en-ca": "en", "en-au": "en",
  ja: "ja", ko: "ko", ru: "ru", uk: "ru", hi: "hi", bn: "hi", it: "it", tr: "tr"
}

// The labels, in the language of whoever is reading them. Numbers and units are
// kept apart so an interval can be built instead of stored, which is what lets
// "5 min" be "5 分" or "5 د" without a separate line for every duration.
var STRINGS = {
  en: {
    schedule: "Change automatically",
    themes: "Themes",
    sources: "Sources",
    next: "Next wallpaper",
    working: "Searching",
    skip: "Not this one",
    favorite: "Add to favorites",
    unfavorite: "Remove from favorites",
    favorites: "Favorites",
    onlyFavorites: "Only favorites",
    noFavorites: "No favorites yet",
    noSources: "Every source is switched off, so turn one on in Sources",
    noFilter: "No theme is chosen, so nothing is filtered",
    ready: "{n} ready",
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
    off: "Off",
    minUnit: "{n} min",
    hourUnit: "{n} h",
    dayUnit: "1 day",
    theme_nature: "Nature", theme_space: "Space", theme_architecture: "Architecture",
    theme_animals: "Animals", theme_photos: "Photos", theme_anime: "Anime",
    anyTheme: "any theme"
  },
  fr: {
    schedule: "Changement automatique",
    themes: "Thèmes",
    sources: "Sources",
    next: "Fond suivant",
    working: "Recherche",
    skip: "Pas celui-ci",
    favorite: "Ajouter aux favoris",
    unfavorite: "Retirer des favoris",
    favorites: "Favoris",
    onlyFavorites: "Favoris uniquement",
    noFavorites: "Aucun favori pour l'instant",
    noSources: "Toutes les sources sont désactivées, réactivez-en une dans Sources",
    noFilter: "Aucun thème choisi, donc aucun filtre",
    ready: "{n} en réserve",
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
    off: "Désactivé",
    minUnit: "{n} min",
    hourUnit: "{n} h",
    dayUnit: "1 jour",
    theme_nature: "Nature", theme_space: "Espace", theme_architecture: "Architecture",
    theme_animals: "Animaux", theme_photos: "Photos", theme_anime: "Anime",
    anyTheme: "tous les thèmes"
  },
  es: {
    schedule: "Cambio automático",
    themes: "Temas",
    sources: "Fuentes",
    next: "Siguiente fondo",
    working: "Buscando",
    skip: "Este no",
    favorite: "Añadir a favoritos",
    unfavorite: "Quitar de favoritos",
    favorites: "Favoritos",
    onlyFavorites: "Solo favoritos",
    noFavorites: "Todavía no hay favoritos",
    noSources: "Todas las fuentes están desactivadas, activa una en Fuentes",
    noFilter: "No hay ningún tema elegido, así que no se filtra nada",
    ready: "{n} listos",
    closeHint: "Esc cierra, n pasa al siguiente, s descarta este",
    empty: "Aún no hay fondo de pantalla",
    loading: "Cargando",
    offline: "Ninguna fuente respondió, se reintenta en 5 minutos",
    offNotice: "El cambio automático está desactivado",
    soon: "En cualquier momento",
    inMinutes: "En {n} min",
    inHours: "En {n} h",
    inDays: "En {n} días",
    inOneDay: "En 1 día",
    off: "Desactivado",
    minUnit: "{n} min",
    hourUnit: "{n} h",
    dayUnit: "1 día",
    theme_nature: "Naturaleza", theme_space: "Espacio", theme_architecture: "Arquitectura",
    theme_animals: "Animales", theme_photos: "Fotos", theme_anime: "Anime",
    anyTheme: "cualquier tema"
  },
  de: {
    schedule: "Automatischer Wechsel",
    themes: "Themen",
    sources: "Quellen",
    next: "Nächstes Hintergrundbild",
    working: "Suche läuft",
    skip: "Dieses nicht",
    favorite: "Zu Favoriten hinzufügen",
    unfavorite: "Aus Favoriten entfernen",
    favorites: "Favoriten",
    onlyFavorites: "Nur Favoriten",
    noFavorites: "Noch keine Favoriten",
    noSources: "Alle Quellen sind ausgeschaltet, schalte eine unter Quellen ein",
    noFilter: "Kein Thema gewählt, also wird nichts gefiltert",
    ready: "{n} bereit",
    closeHint: "Esc schließt, n nimmt das nächste, s überspringt dieses",
    empty: "Noch kein Hintergrundbild",
    loading: "Lädt",
    offline: "Keine Quelle hat geantwortet, neuer Versuch in 5 Minuten",
    offNotice: "Der automatische Wechsel ist aus",
    soon: "Jeden Moment",
    inMinutes: "In {n} Min.",
    inHours: "In {n} Std.",
    inDays: "In {n} Tagen",
    inOneDay: "In 1 Tag",
    off: "Aus",
    minUnit: "{n} Min.",
    hourUnit: "{n} Std.",
    dayUnit: "1 Tag",
    theme_nature: "Natur", theme_space: "Weltraum", theme_architecture: "Architektur",
    theme_animals: "Tiere", theme_photos: "Fotos", theme_anime: "Anime",
    anyTheme: "jedes Thema"
  },
  it: {
    schedule: "Cambio automatico",
    themes: "Temi",
    sources: "Fonti",
    next: "Sfondo successivo",
    working: "Ricerca in corso",
    skip: "Non questo",
    favorite: "Aggiungi ai preferiti",
    unfavorite: "Rimuovi dai preferiti",
    favorites: "Preferiti",
    onlyFavorites: "Solo preferiti",
    noFavorites: "Ancora nessun preferito",
    noSources: "Tutte le fonti sono disattivate, attivane una in Fonti",
    noFilter: "Nessun tema scelto, quindi nessun filtro",
    ready: "{n} pronti",
    closeHint: "Esc chiude, n passa al successivo, s scarta questo",
    empty: "Nessuno sfondo per ora",
    loading: "Caricamento",
    offline: "Nessuna fonte ha risposto, nuovo tentativo fra 5 minuti",
    offNotice: "Il cambio automatico è disattivato",
    soon: "Da un momento all'altro",
    inMinutes: "Fra {n} min",
    inHours: "Fra {n} h",
    inDays: "Fra {n} giorni",
    inOneDay: "Fra 1 giorno",
    off: "Disattivato",
    minUnit: "{n} min",
    hourUnit: "{n} h",
    dayUnit: "1 giorno",
    theme_nature: "Natura", theme_space: "Spazio", theme_architecture: "Architettura",
    theme_animals: "Animali", theme_photos: "Foto", theme_anime: "Anime",
    anyTheme: "qualsiasi tema"
  },
  pt: {
    schedule: "Mudança automática",
    themes: "Temas",
    sources: "Fontes",
    next: "Próximo fundo",
    working: "Procurando",
    skip: "Este não",
    favorite: "Adicionar aos favoritos",
    unfavorite: "Remover dos favoritos",
    favorites: "Favoritos",
    onlyFavorites: "Somente favoritos",
    noFavorites: "Ainda sem favoritos",
    noSources: "Todas as fontes estão desligadas, ligue uma em Fontes",
    noFilter: "Nenhum tema escolhido, então nada é filtrado",
    ready: "{n} prontos",
    closeHint: "Esc fecha, n pega o próximo, s descarta este",
    empty: "Ainda sem papel de parede",
    loading: "Carregando",
    offline: "Nenhuma fonte respondeu, nova tentativa em 5 minutos",
    offNotice: "A mudança automática está desligada",
    soon: "A qualquer momento",
    inMinutes: "Em {n} min",
    inHours: "Em {n} h",
    inDays: "Em {n} dias",
    inOneDay: "Em 1 dia",
    off: "Desligado",
    minUnit: "{n} min",
    hourUnit: "{n} h",
    dayUnit: "1 dia",
    theme_nature: "Natureza", theme_space: "Espaço", theme_architecture: "Arquitetura",
    theme_animals: "Animais", theme_photos: "Fotos", theme_anime: "Anime",
    anyTheme: "qualquer tema"
  },
  ru: {
    schedule: "Автоматическая смена",
    themes: "Темы",
    sources: "Источники",
    next: "Следующие обои",
    working: "Поиск",
    skip: "Не эти",
    favorite: "Добавить в избранное",
    unfavorite: "Убрать из избранного",
    favorites: "Избранное",
    onlyFavorites: "Только избранное",
    noFavorites: "Избранного пока нет",
    noSources: "Все источники выключены, включите один в разделе Источники",
    noFilter: "Тема не выбрана, значит фильтра нет",
    ready: "Готово: {n}",
    closeHint: "Esc закрывает, n берёт следующие, s пропускает эти",
    empty: "Обоев пока нет",
    loading: "Загрузка",
    offline: "Ни один источник не ответил, повтор через 5 минут",
    offNotice: "Автоматическая смена выключена",
    soon: "Вот-вот",
    inMinutes: "Через {n} мин",
    inHours: "Через {n} ч",
    inDays: "Через {n} дн.",
    inOneDay: "Через 1 день",
    off: "Выключено",
    minUnit: "{n} мин",
    hourUnit: "{n} ч",
    dayUnit: "1 день",
    theme_nature: "Природа", theme_space: "Космос", theme_architecture: "Архитектура",
    theme_animals: "Животные", theme_photos: "Фото", theme_anime: "Аниме",
    anyTheme: "любая тема"
  },
  tr: {
    schedule: "Otomatik değişim",
    themes: "Temalar",
    sources: "Kaynaklar",
    next: "Sonraki duvar kağıdı",
    working: "Aranıyor",
    skip: "Bu değil",
    favorite: "Favorilere ekle",
    unfavorite: "Favorilerden çıkar",
    favorites: "Favoriler",
    onlyFavorites: "Yalnızca favoriler",
    noFavorites: "Henüz favori yok",
    noSources: "Tüm kaynaklar kapalı, Kaynaklar bölümünden birini aç",
    noFilter: "Tema seçilmedi, yani filtre yok",
    ready: "{n} hazır",
    closeHint: "Esc kapatır, n sonrakini alır, s bunu atlar",
    empty: "Henüz duvar kağıdı yok",
    loading: "Yükleniyor",
    offline: "Hiçbir kaynak yanıt vermedi, 5 dakika sonra yeniden denenecek",
    offNotice: "Otomatik değişim kapalı",
    soon: "Her an",
    inMinutes: "{n} dk sonra",
    inHours: "{n} sa sonra",
    inDays: "{n} gün sonra",
    inOneDay: "1 gün sonra",
    off: "Kapalı",
    minUnit: "{n} dk",
    hourUnit: "{n} sa",
    dayUnit: "1 gün",
    theme_nature: "Doğa", theme_space: "Uzay", theme_architecture: "Mimari",
    theme_animals: "Hayvanlar", theme_photos: "Fotoğraflar", theme_anime: "Anime",
    anyTheme: "her tema"
  },
  ar: {
    schedule: "تغيير تلقائي",
    themes: "الأنماط",
    sources: "المصادر",
    next: "الخلفية التالية",
    working: "جارٍ البحث",
    skip: "ليس هذه",
    favorite: "أضف إلى المفضلة",
    unfavorite: "أزل من المفضلة",
    favorites: "المفضلة",
    onlyFavorites: "المفضلة فقط",
    noFavorites: "لا توجد مفضلة بعد",
    noSources: "كل المصادر متوقفة، فعّل واحدًا من المصادر",
    noFilter: "لم يُختر نمط، فلا يوجد أي تصفية",
    ready: "{n} جاهزة",
    closeHint: "Esc يغلق، n التالية، s تجاهل هذه",
    empty: "لا توجد خلفية بعد",
    loading: "جارٍ التحميل",
    offline: "لم يستجب أي مصدر، ستتم إعادة المحاولة بعد 5 دقائق",
    offNotice: "التغيير التلقائي متوقف",
    soon: "في أي لحظة",
    inMinutes: "بعد {n} دقيقة",
    inHours: "بعد {n} ساعة",
    inDays: "بعد {n} يومًا",
    inOneDay: "بعد يوم واحد",
    off: "متوقف",
    minUnit: "{n} د",
    hourUnit: "{n} س",
    dayUnit: "يوم واحد",
    theme_nature: "الطبيعة", theme_space: "الفضاء", theme_architecture: "العمارة",
    theme_animals: "الحيوانات", theme_photos: "صور", theme_anime: "أنمي",
    anyTheme: "أي نمط"
  },
  hi: {
    schedule: "स्वचालित बदलाव",
    themes: "शैलियाँ",
    sources: "स्रोत",
    next: "अगला वॉलपेपर",
    working: "खोज रहे हैं",
    skip: "यह नहीं",
    favorite: "पसंदीदा में जोड़ें",
    unfavorite: "पसंदीदा से हटाएँ",
    favorites: "पसंदीदा",
    onlyFavorites: "केवल पसंदीदा",
    noFavorites: "अभी कोई पसंदीदा नहीं",
    noSources: "सभी स्रोत बंद हैं, स्रोत में से एक चालू करें",
    noFilter: "कोई शैली चुनी नहीं गई, इसलिए कोई छँटाई नहीं",
    ready: "{n} तैयार",
    closeHint: "Esc बंद करता है, n अगला लेता है, s इसे छोड़ता है",
    empty: "अभी कोई वॉलपेपर नहीं",
    loading: "लोड हो रहा है",
    offline: "किसी स्रोत ने जवाब नहीं दिया, 5 मिनट में फिर कोशिश",
    offNotice: "स्वचालित बदलाव बंद है",
    soon: "कभी भी",
    inMinutes: "{n} मिनट में",
    inHours: "{n} घंटे में",
    inDays: "{n} दिन में",
    inOneDay: "1 दिन में",
    off: "बंद",
    minUnit: "{n} मिनट",
    hourUnit: "{n} घंटे",
    dayUnit: "1 दिन",
    theme_nature: "प्रकृति", theme_space: "अंतरिक्ष", theme_architecture: "वास्तुकला",
    theme_animals: "जानवर", theme_photos: "तस्वीरें", theme_anime: "एनिमे",
    anyTheme: "कोई भी शैली"
  },
  zh: {
    schedule: "自动更换",
    themes: "主题",
    sources: "来源",
    next: "下一张壁纸",
    working: "正在查找",
    skip: "不要这张",
    favorite: "加入收藏",
    unfavorite: "取消收藏",
    favorites: "收藏",
    onlyFavorites: "仅收藏",
    noFavorites: "还没有收藏",
    noSources: "所有来源都已关闭，请在来源中开启一个",
    noFilter: "未选择主题，因此不做筛选",
    ready: "已备好 {n} 张",
    closeHint: "Esc 关闭，n 下一张，s 跳过这张",
    empty: "还没有壁纸",
    loading: "加载中",
    offline: "没有来源响应，5 分钟后重试",
    offNotice: "自动更换已关闭",
    soon: "随时",
    inMinutes: "{n} 分钟后",
    inHours: "{n} 小时后",
    inDays: "{n} 天后",
    inOneDay: "1 天后",
    off: "关闭",
    minUnit: "{n} 分钟",
    hourUnit: "{n} 小时",
    dayUnit: "1 天",
    theme_nature: "自然", theme_space: "太空", theme_architecture: "建筑",
    theme_animals: "动物", theme_photos: "摄影", theme_anime: "动漫",
    anyTheme: "任意主题"
  },
  ja: {
    schedule: "自動切り替え",
    themes: "テーマ",
    sources: "ソース",
    next: "次の壁紙",
    working: "検索中",
    skip: "これは違う",
    favorite: "お気に入りに追加",
    unfavorite: "お気に入りから削除",
    favorites: "お気に入り",
    onlyFavorites: "お気に入りのみ",
    noFavorites: "お気に入りはまだありません",
    noSources: "すべてのソースが無効です。ソースで一つ有効にしてください",
    noFilter: "テーマが選ばれていないので、絞り込みはありません",
    ready: "{n} 枚準備済み",
    closeHint: "Esc で閉じる、n で次、s でこれを除外",
    empty: "壁紙はまだありません",
    loading: "読み込み中",
    offline: "どのソースも応答しませんでした。5 分後に再試行します",
    offNotice: "自動切り替えは無効です",
    soon: "まもなく",
    inMinutes: "{n} 分後",
    inHours: "{n} 時間後",
    inDays: "{n} 日後",
    inOneDay: "1 日後",
    off: "無効",
    minUnit: "{n} 分",
    hourUnit: "{n} 時間",
    dayUnit: "1 日",
    theme_nature: "自然", theme_space: "宇宙", theme_architecture: "建築",
    theme_animals: "動物", theme_photos: "写真", theme_anime: "アニメ",
    anyTheme: "すべてのテーマ"
  },
  ko: {
    schedule: "자동 변경",
    themes: "테마",
    sources: "소스",
    next: "다음 배경",
    working: "검색 중",
    skip: "이건 아님",
    favorite: "즐겨찾기에 추가",
    unfavorite: "즐겨찾기에서 제거",
    favorites: "즐겨찾기",
    onlyFavorites: "즐겨찾기만",
    noFavorites: "아직 즐겨찾기가 없습니다",
    noSources: "모든 소스가 꺼져 있습니다. 소스에서 하나를 켜세요",
    noFilter: "테마를 고르지 않아 필터가 없습니다",
    ready: "{n}장 준비됨",
    closeHint: "Esc 닫기, n 다음, s 이건 건너뛰기",
    empty: "아직 배경이 없습니다",
    loading: "불러오는 중",
    offline: "어떤 소스도 응답하지 않았습니다. 5분 후 다시 시도합니다",
    offNotice: "자동 변경이 꺼져 있습니다",
    soon: "곧",
    inMinutes: "{n}분 후",
    inHours: "{n}시간 후",
    inDays: "{n}일 후",
    inOneDay: "1일 후",
    off: "끔",
    minUnit: "{n}분",
    hourUnit: "{n}시간",
    dayUnit: "1일",
    theme_nature: "자연", theme_space: "우주", theme_architecture: "건축",
    theme_animals: "동물", theme_photos: "사진", theme_anime: "애니메",
    anyTheme: "모든 테마"
  }
}

// "auto" follows the desktop, which is what a plugin should do by default. A
// language can be forced in the config for anyone who wants English on a
// French desktop, or the other way round.
var language = "auto"

function setLanguage(code) {
  language = LANGUAGE_CODES.indexOf(code) >= 0 ? code : "auto"
}

function languageCodes() { return LANGUAGE_CODES }

// The effective language: a code when one was chosen, the system language
// otherwise, and English when the system language is not one of the thirteen.
function localeKey(code) {
  var chosen = code === undefined ? language : code
  if (chosen && chosen !== "auto") return chosen
  try {
    var name = Qt.locale().name.toLowerCase().replace("_", "-")
    var base = name.split("-")[0]
    if (LOCALE_ALIASES[name]) return LOCALE_ALIASES[name]
    if (LOCALE_ALIASES[base]) return LOCALE_ALIASES[base]
  } catch (error) {
    return "en"
  }
  return "en"
}

// The whole table, for interfaces that read their labels from a QML property:
// a binding on that property follows the language, a call to t() does not.
function stringsFor(code) {
  return STRINGS[localeKey(code)] || STRINGS.en
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

// A credit is text, not a document. A Text element decides on its own how to
// read what it is given, and rich text can carry an image whose URL a renderer
// will happily fetch, so the markup and the control characters are removed
// here, once, for every surface that shows a string from a source.
function singleLine(value, max) {
  if (typeof value !== "string") return ""
  var flat = value.replace(/<[^>]{0,300}>/g, " ")
  flat = flat.replace(/[<>]/g, "")
  flat = flat.replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
  flat = flat.replace(/\s+/g, " ").trim()
  var limit = max || 200
  return flat.length > limit ? flat.slice(0, limit - 1) + "..." : flat
}

function sourceLabel(id) {
  for (var i = 0; i < SOURCES.length; i++)
    if (SOURCES[i].id === id) return SOURCES[i].label
  // An id this version does not know about is shown as it is, but never raw.
  return id === "" ? "" : singleLine(id, 24)
}

function themeLabel(id) {
  if (id === "any") return t("anyTheme")
  for (var i = 0; i < THEMES.length; i++)
    if (THEMES[i].id === id) return t("theme_" + THEMES[i].id)
  return ""
}

// The panel shows a number of minutes; the wording around that number comes
// from the language, so a new interval needs no new translation.
function intervalLabel(minutes) {
  var m = Number(minutes) || 0
  if (m <= 0) return t("off")
  if (m < 60) return t("minUnit", { n: m })
  if (m < 1440) return t("hourUnit", { n: Math.round(m / 60) })
  return t("dayUnit")
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
  if (state && state.lang) setLanguage(state.lang)
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
