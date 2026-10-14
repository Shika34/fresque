# Fresque

Des fonds d'écran de qualité pour [Omarchy](https://omarchy.org/), sans réglage
à faire : vous installez, et il y a un fond d'écran. La rotation est
journalière par défaut, les sources sont choisies pour la qualité des images,
et tout ce qui a été téléchargé reste chez vous.

```
omarchy plugin add https://github.com/mitch/fresque.git --enable
```

Rien d'autre à faire. Fresque installe son premier fond d'écran à
l'activation, puis en change un par jour.

## Ce qu'il fait

| | |
|---|---|
| **4 sources, aucune clé d'API** | Wallhaven (le top du mois), l'image du jour de Bing, les images remarquables de Wikimedia Commons, les photographies Unsplash via Picsum |
| **Le fond d'écran, pas une image au hasard** | Chaque source est filtrée sur la résolution de votre plus grand écran et sur son format : une image plus petite que votre écran, ou dans un format qui serait rogné de moitié, n'est jamais proposée |
| **Rotation** | Jour (défaut), 6 h, 3 h, 1 h, 30 min, 15 min, 5 min, ou désactivée |
| **Bibliothèque locale** | Chaque image appliquée est conservée dans `~/Pictures/Fresque/` avec un fichier d'accompagnement qui garde la source, l'auteur et la licence. La rotation fonctionne donc aussi hors ligne |
| **Pas de doublon** | Une image déjà vue n'est pas reproposée, et la même image venue de deux sources n'occupe qu'un seul fichier (empreinte SHA-256) |
| **Crédits affichés** | Le panneau montre la source, la résolution et l'auteur quand il y en a un, avec un lien vers la page d'origine |

## Utilisation

| Geste | Effet |
|---|---|
| Clic gauche sur la pastille | Ouvre le panneau |
| Clic droit | Fond d'écran suivant |
| `n` (panneau ouvert) | Fond d'écran suivant |
| `Échap` | Ferme le panneau |

Le panneau tient en trois choses : l'image en cours avec ses crédits, les huit
choix de rotation, et les quatre sources à activer ou désactiver. Il n'y a rien
d'autre à régler : les filtres de résolution suivent vos écrans, et les
paramètres de recherche sont figés dans les sources, côté moteur.

## Réglages en ligne de commande

Le panneau est un confort, pas une obligation — tout est dans le script :

```sh
fresque status                        # fond actuel, rotation, sources (JSON)
fresque next                          # télécharge et applique le fond suivant
fresque verify                        # interroge chaque source, ne change rien
fresque clean 60                      # ne garde que les 60 dernières images
fresque touch                         # relance le compteur de rotation
fresque config set rotateMinutes 60   # 0, 5, 15, 30, 60, 180, 360, 1440
fresque config set sources.bing false # désactive une source
```

Le script vit dans le dossier du plugin :

```sh
~/.config/omarchy/plugins/mitch.fresque/bin/fresque status
```

## Ce qui sort de la machine

Une requête HTTPS vers la source choisie puis une par image téléchargée, quand
la rotation arrive à échéance ou quand vous cliquez « Fond suivant ». Aucune
télémétrie, aucun compte, aucune clé d'API, aucune donnée envoyée ailleurs.
Chaque source est interrogée sur son API publique et les images restent celles
que le site sert au public.

## Où sont les fichiers

| Chemin | Rôle |
|---|---|
| `~/Pictures/Fresque/` | La bibliothèque : images + `<image>.source.json` (source, auteur, licence, lien) |
| `~/.config/omarchy/fresque.json` | Les réglages |
| `~/.local/state/fresque/` | Fond actuel et identifiants déjà vus |
| `~/.config/omarchy/backgrounds/<thème>/` | Lien vers les images appliquées, pour qu'elles apparaissent aussi dans le sélecteur de fond natif d'Omarchy |

## Désinstallation

```sh
omarchy plugin remove mitch.fresque
```

La bibliothèque et les réglages sont laissés en place ; supprimez-les si vous
voulez les images en moins :

```sh
rm -rf ~/Pictures/Fresque ~/.local/state/fresque ~/.config/omarchy/fresque.json
```

## Ce qu'il ne fait pas

- Pas d'ajout de source personnalisée : les quatre sources sont dans le moteur,
  et c'est ce qui garantit la qualité des images.
- Pas de fond d'écran différent par écran : Omarchy affiche un seul fond sur
  tous les écrans. Fresque choisit en revanche des images à la résolution et au
  format de votre plus grand écran, ce qui est la seule partie de ce problème
  qu'un plugin peut résoudre.
- Pas de vidéo, pas de shader, pas de fond animé.

## Développement

```sh
git clone https://github.com/mitch/fresque.git \
  ~/.config/omarchy/plugins/mitch.fresque
omarchy plugin validate ~/.config/omarchy/plugins/mitch.fresque
omarchy-shell shell rescanPlugins
omarchy plugin enable mitch.fresque
```

Après une modification de `.qml`, `omarchy-restart-shell` (le `rescanPlugins`
seul ne recharge pas le code). Le moteur se teste directement, sans toucher au
fond d'écran ni au dossier du thème :

```sh
FRESQUE_DRY_RUN=1 FRESQUE_LIBRARY=/tmp/fresque-test \
  bin/fresque next && bin/fresque verify
```

## Licences des sources

Fresque ne redistribue aucune image. Chaque source est utilisée via son API
publique et sous ses propres conditions, que le fichier d'accompagnement
rappelle : contenu tiers pour Wallhaven, © Bing et ses auteurs, licence libre
indiquée image par image pour Wikimedia Commons, Unsplash License pour Picsum.

## Licence

MIT — voir [LICENSE](LICENSE).
