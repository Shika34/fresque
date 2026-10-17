# Fresque

**A pleasure for the eyes.** Quality wallpapers for [Omarchy](https://omarchy.org/),
with nothing to configure: you install it, and there is a wallpaper.

![The Fresque panel open on a desktop](docs/hero.jpg)

It is made to be looked at. Every picture is at least as large as your screen and
shaped like it, the author and the licence sit right there in the panel, and the
whole thing changes on its own. It changes once a day by default, and the folder
it keeps stays at the size you choose.

```sh
omarchy plugin add https://github.com/Shika34/fresque.git --enable
```

Nothing else to do. Fresque installs its first wallpaper when it is enabled and
then takes a new one every day.

## What it does

| | |
|---|---|
| **Seven sources, no API key** | Bing's picture of the day, Wikimedia Commons featured and quality photography, NOIRLab's image of the week for the night sky, the wallpapers Omarchy itself ships, Konachan and Yande.re anime art, and Unsplash photographs served through Picsum |
| **Wallpapers, not random images** | Every candidate has to be at least as large as your largest screen, and shaped like a widescreen desktop. Portrait shots and long panoramas are dropped before anything is downloaded, the file's real size is measured again after the download, and obvious non-photographs (museum specimens, murals, maps, diagrams) are filtered out by keyword |
| **Nothing you would not want decoded** | A picture is kept at twice your screen at most, never above 50 megapixels or 12000 pixels on a side, and it is re-encoded on the way in. The shell only ever opens a plain JPEG this plugin wrote, so the metadata a file can carry, the canvas it can claim and the colours it can declare stay in the short lived tool that read it |
| **A theme filter** | Nature, Space, Architecture, Animals, Photos, Anime. A theme that is off is never queried, so nothing from it can reach your screen, and a source that cannot serve the chosen themes is not queried at all. Switching every theme off means nothing is filtered, rather than nothing is allowed |
| **An instant switch** | Two wallpapers are downloaded ahead of time, so asking for the next one takes about a third of a second instead of a few seconds. One is fetched in the background as soon as you pick one, and the pool never grows past four |
| **"Not this one"** | The picture on screen is blocked and replaced in one click. It will not come back |
| **Favorites** | One click moves the picture on screen into `~/Pictures/Fresque/Favorites/`. Favorites are never pruned, and "Only favorites" turns the rotation into a loop over what you kept |
| **Change automatically** | 1 day (default), 6 h, 3 h, 1 h, 30 min, 15 min, 5 min, or off |
| **A library with a ceiling** | `~/Pictures/Fresque/` holds the images and nothing else. It is trimmed to your limit (30 by default), oldest first, and never drops the wallpaper you are looking at. All the metadata lives in the state directory instead |
| **Credits** | The panel shows the source, the size, the theme and the author |

## What it can put on your screen

![An autumn waterfall in West Virginia, a lava cave in the Azores, an anime scene from Konachan](docs/wallpapers.jpg)

Three pictures kept in the favorites, from three of the seven sources: Bing's
photograph of the day, Wikimedia Commons, and Konachan. Each one keeps its
author and its licence in the panel.

## Sources

| Source | What it serves | Licence |
|---|---|---|
| Bing | The day's photograph, served with the Photos theme. Nothing else is claimed about it, since the picture is chosen by someone else | Bing, credited to its author |
| Wikimedia Commons | Featured and quality photography, and featured galaxy pictures for Space | Free licence per image, shown in the panel |
| NOIRLab | The image of the week: the Milky Way over an observatory, a comet, an eclipse, the odd galaxy | NOIRLab/NSF/AURA, CC BY 4.0 |
| Omarchy | The wallpapers shipped with your Omarchy themes, plus the ones in your own theme folders. Already on the disk, so nothing is downloaded and nothing is copied: the picture is put on screen where it lies, and "Not this one" blocks it without deleting it | Shipped with Omarchy |
| Konachan, Yande.re | Anime art at 4K and beyond, for the Anime theme | Fan art, credited to its artist |
| Unsplash via Picsum | Photographs, theme "Photos" | Unsplash License |

Every request to Konachan and Yande.re is pinned to the safe rating and to your
screen size, so nothing else can come back from them. The panel dims a source
whose themes are all switched off, so it is obvious why it stays quiet.

## Usage

![The panel: preview and credit, interval, theme filter, sources, favorites, actions](docs/panel.jpg)

![The bar pill, between the tray and the other widgets](docs/bar.jpg)

| Gesture | Effect |
|---|---|
| Left click on the pill | Opens the panel |
| Right click | Next wallpaper |
| `n` while the panel is open | Next wallpaper |
| `s` while the panel is open | Block this one and take another |
| `f` while the panel is open | Add or remove the current wallpaper from favorites |
| `Esc` | Closes the panel |

The panel is four rows of choices and three buttons. The intervals, the themes,
the sources and the favorites switch all start in the state you would have
picked anyway.

The interface follows your system language. Thirteen languages are built in:
Chinese, Hindi, Spanish, French, Arabic, Portuguese, Russian, Japanese, German,
Italian, Korean, Turkish and English, and anything else falls back to English.
Set `language` to one of their codes to force one.

## Command line

The panel is a convenience, not a requirement. The engine is a script in the
plugin folder and it does everything the panel does.

```sh
fresque status                          # current wallpaper, rotation, themes, sources, favorites as JSON
fresque next                            # apply the next wallpaper (instant when one is ready)
fresque prefetch 2                       # download the next two in advance
fresque skip                            # block this one and take another
fresque favorite                        # move the current wallpaper into Favorites
fresque unfavorite                      # move it back into the library
fresque verify                          # ask every source and theme for one answer
fresque clean 40                        # keep the newest 40 images
fresque touch                           # restart the rotation clock
fresque config set rotateMinutes 60     # 0, 5, 15, 30, 60, 180, 360, 1440
fresque config set keepLast 50          # how many images the library may hold
fresque config set favoritesOnly true   # rotate over the favorites only
fresque config set language ja          # auto or en zh hi es fr ar pt ru ja de it ko tr
fresque config set themes.space false   # turn a theme off (nature space architecture animals photos anime)
fresque config set sources.noirlab false # turn a source off (bing wikimedia noirlab konachan yandere picsum)
```

The script lives at `~/.config/omarchy/plugins/io.github.shika34.fresque/bin/fresque`.

### What a picture is allowed to be

The download limits say nothing about what a file costs once it is decoded. A PNG
of forty kilobytes can describe a canvas of several gigabytes, or carry forty
megabytes of compressed text that a renderer inflates before it scales anything.
So nothing a source served is handed to the shell: each picture is read, stripped,
resized to twice the screen at most and written back as a JPEG, in a short lived
tool with its own memory ceiling. What the panel and Omarchy's background picker
open is a file this plugin produced. The same rule covers what an earlier version
left behind: a picture in the library, in the favorites, or in the pool prepared
ahead of time is rewritten the first time it is used, and a settings schema
change drops the pool rather than trust it.

## Requirements

Everything Fresque needs is already on an Omarchy install: `bash`, `curl` and
`jq`. Measuring a picture uses `vipsheader` or `magick` when one of the two is
present, and falls back to the size the source declares when neither is. The
interface is QML on the Quickshell that Omarchy ships.

## What leaves the machine

One HTTPS request to the chosen source when a change is due or when you ask for
the next wallpaper, then one more for the image itself. The Omarchy source asks
for nothing at all: it reads the wallpapers already installed on the machine. No account, no API key,
no telemetry, nothing sent anywhere else. Each source is queried through its
public API and the images are the ones the site already serves to the public.

## Files

| Path | Role |
|---|---|
| `~/Pictures/Fresque/` | The wallpapers, and only the wallpapers |
| `~/Pictures/Fresque/Favorites/` | The ones you kept. Never pruned, never touched by the size limit |
| `~/.config/omarchy/fresque.json` | Settings |
| `~/.local/state/fresque/` | Current wallpaper, credits, history, blocked images |
| `~/.config/omarchy/backgrounds/<theme>/` | Links to the applied images, so they also show up in Omarchy's own background picker |

## Uninstall

```sh
omarchy plugin remove io.github.shika34.fresque
```

The library and the settings are left in place. Remove them as well if you want
the images gone:

```sh
rm -rf ~/Pictures/Fresque ~/.local/state/fresque ~/.config/omarchy/fresque.json
```

## What it does not do

- No custom sources. The seven that ship are the ones that can be used without
  an API key and without scraping a website.
- No separate wallpaper per screen. Omarchy draws one background across every
  screen, so Fresque picks pictures that fit your largest one instead.
- No video, no shader, no animated background.

## Development

For working on the plugin itself. A checkout is not an installation step:
`omarchy plugin add` above already places the files, and nothing is ever built,
compiled or executed from the network at install time. Fresque is QML and shell
run from the repository as it is.

```sh
git clone https://github.com/Shika34/fresque.git \
  ~/.config/omarchy/plugins/io.github.shika34.fresque
omarchy plugin validate ~/.config/omarchy/plugins/io.github.shika34.fresque
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.shika34.fresque
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
