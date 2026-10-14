# Fresque

Quality wallpapers for [Omarchy](https://omarchy.org/). You install it and there
is a wallpaper. It changes once a day, it only ever offers pictures large enough
for your screen, and the folder it keeps stays at a size you choose.

```sh
omarchy plugin add https://github.com/mitch/fresque.git --enable
```

Nothing else to do. Fresque installs its first wallpaper when it is enabled and
then takes a new one every day.

## What it does

| | |
|---|---|
| **Four sources, no API key** | Bing's picture of the day, Wikimedia Commons featured and quality photography, NASA's image library, and Unsplash photographs served through Picsum |
| **Wallpapers, not random images** | Every candidate has to be at least as large as your largest screen, and shaped like a widescreen desktop. Portrait shots and long panoramas are dropped before anything is downloaded, and the file's real size is measured again after the download |
| **A theme filter** | Nature, Space, Architecture, Animals, Photos. A theme that is off is never queried, so nothing from it can reach your screen |
| **"Not this one"** | The picture on screen is blocked and replaced in one click. It will not come back |
| **Change automatically** | 1 day (default), 6 h, 3 h, 1 h, 30 min, 15 min, 5 min, or off |
| **A library with a ceiling** | `~/Pictures/Fresque/` holds the images and nothing else. It is trimmed to your limit (30 by default), oldest first, and never drops the wallpaper you are looking at. All the metadata lives in the state directory instead |
| **Credits** | The panel shows the source, the size, the theme and the author, with a link to the original page |

## Sources

| Source | What it serves | Licence |
|---|---|---|
| Bing | The day's photograph, always, whatever themes are on | Bing, credited to its author |
| Wikimedia Commons | Featured and quality photography, by theme | Free licence per image, shown in the panel |
| NASA | Space and Earth imagery, by theme | Public domain |
| Unsplash via Picsum | Photographs, theme "Photos" | Unsplash License |

Bing and Unsplash cannot be filtered by theme, because the one is a single daily
picture and the other carries no tags. The panel dims a source when the themes
you picked leave it nothing to serve.

## Usage

| Gesture | Effect |
|---|---|
| Left click on the pill | Opens the panel |
| Right click | Next wallpaper |
| `n` while the panel is open | Next wallpaper |
| `s` while the panel is open | Block this one and take another |
| `Esc` | Closes the panel |

The panel is three rows of choices and two buttons. The intervals, the themes and
the sources all start in the state you would have picked anyway.

The interface follows your system language. English and French are built in, and
anything else falls back to English.

## Command line

The panel is a convenience, not a requirement. The engine is a script in the
plugin folder and it does everything the panel does.

```sh
fresque status                          # current wallpaper, rotation, themes, sources as JSON
fresque next                            # download and apply the next wallpaper
fresque skip                            # block this one and take another
fresque verify                          # ask every source and theme for one answer
fresque clean 40                        # keep the newest 40 images
fresque touch                           # restart the rotation clock
fresque config set rotateMinutes 60     # 0, 5, 15, 30, 60, 180, 360, 1440
fresque config set keepLast 50          # how many images the library may hold
fresque config set themes.space false   # turn a theme off
fresque config set sources.nasa false   # turn a source off
```

The script lives at `~/.config/omarchy/plugins/mitch.fresque/bin/fresque`.

## What leaves the machine

One HTTPS request to the chosen source when a change is due or when you ask for
the next wallpaper, then one more for the image itself. No account, no API key,
no telemetry, nothing sent anywhere else. Each source is queried through its
public API and the images are the ones the site already serves to the public.

## Files

| Path | Role |
|---|---|
| `~/Pictures/Fresque/` | The wallpapers, and only the wallpapers |
| `~/.config/omarchy/fresque.json` | Settings |
| `~/.local/state/fresque/` | Current wallpaper, credits, history, blocked images |
| `~/.config/omarchy/backgrounds/<theme>/` | Links to the applied images, so they also show up in Omarchy's own background picker |

## Uninstall

```sh
omarchy plugin remove mitch.fresque
```

The library and the settings are left in place. Remove them as well if you want
the images gone:

```sh
rm -rf ~/Pictures/Fresque ~/.local/state/fresque ~/.config/omarchy/fresque.json
```

## What it does not do

- No custom sources. The four that ship are the ones that can be used without an
  API key and without scraping a website.
- No separate wallpaper per screen. Omarchy draws one background across every
  screen, so Fresque picks pictures that fit your largest one instead.
- No video, no shader, no animated background.

## Development

```sh
git clone https://github.com/mitch/fresque.git \
  ~/.config/omarchy/plugins/mitch.fresque
omarchy plugin validate ~/.config/omarchy/plugins/mitch.fresque
omarchy-shell shell rescanPlugins
omarchy plugin enable mitch.fresque
```

Any `.qml` edit needs `omarchy-restart-shell`. `rescanPlugins` only discovers
new folders, it does not reload code.

The engine can be exercised without touching the desktop or the theme folder:

```sh
FRESQUE_DRY_RUN=1 FRESQUE_LIBRARY=/tmp/fresque-test \
  bin/fresque next && bin/fresque verify
```

## Licence

MIT. See [LICENSE](LICENSE).
