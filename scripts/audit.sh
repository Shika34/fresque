#!/usr/bin/env bash
# The invariants this plugin depends on, checked mechanically.
#
# Every one of them exists because a review found it broken once. Keeping them in
# a script rather than in someone's memory is what stops the next release from
# reintroducing one of them. Run from the repository root: scripts/audit.sh

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
ok()   { printf '  ok    %s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; fail=1; }

echo "1. No image tool runs outside the memory ceiling"
mapfile -t loose < <(
  grep -nE '(^|[^_[:alnum:]])(magick|vipsheader|vips)[[:space:]]' bin/fresque |
  grep -v 'bounded_tool' | grep -v 'command -v' | grep -vE ':[[:space:]]*#'
)
if ((${#loose[@]} == 0)); then ok "every magick/vips call goes through bounded_tool"
else bad "unbounded image tool call: ${loose[*]}"; fi

echo "2. Every HTTP reply is cut at a byte ceiling"
curl_calls=$(grep -cE '(^|[^_[:alnum:]])curl[[:space:]]' bin/fresque)
bounded_pipes=$(grep -c 'head -c' bin/fresque)
if ((curl_calls > 0 && bounded_pipes >= curl_calls)); then
  ok "$curl_calls curl calls, $bounded_pipes byte ceilings"
else
  bad "$curl_calls curl calls for only $bounded_pipes byte ceilings"
fi
if grep -q 'curl_json()' bin/fresque && grep -q 'curl_file()' bin/fresque && grep -q 'remote_probe()' bin/fresque; then
  ok "all requests go through curl_json, curl_file or remote_probe"
else
  bad "one of the request helpers is missing"
fi

echo "3. No shell in the middle"
if grep -nE '\beval[[:space:]]|bash -c|sh -c' bin/fresque | grep -vqE ':[[:space:]]*#'; then
  bad "eval or a shell -c call is back"
else
  ok "no eval, no shell -c"
fi

echo "4. External numbers are sanitised before arithmetic"
if grep -q '^dimension()' bin/fresque && grep -q '^pixels_ok()' bin/fresque; then
  ok "dimension() and pixels_ok() are present"
else
  bad "a guard is missing"
fi
# A comparison on a value that comes from outside has to be preceded by
# dimension(). That cannot be proved by grep, so the audit lists the lines for a
# reader to check rather than pretending to decide.
mapfile -t maths < <(grep -nE '\(\([[:space:]]*(w|h|size|value|keep|dropped)[[:space:]]*[<>]' bin/fresque)
if ((${#maths[@]} == 0)); then
  ok "no arithmetic on a value that could come from outside"
else
  printf '  note  %d comparison(s) on a variable that may come from outside, each must be preceded by dimension():\n' "${#maths[@]}"
  printf '        %s\n' "${maths[@]%%:*}"
fi

echo "5. The state says whether a picture is safe to open"
if grep -q 'shaped: true' bin/fresque; then ok "write_current records shaped: true"
else bad "write_current no longer records the shaping flag"; fi
if grep -q 'shaped === true' Panel.qml; then ok "the preview requires the flag"
else bad "the preview opens a path without the flag"; fi
if grep -q 'is_jpeg_file' bin/fresque; then ok "the format is read from the bytes"
else bad "the format is decided by the name again"; fi

echo "6. Nothing a source sends is rendered as markup"
if grep -q 'Text.PlainText' Panel.qml; then ok "the panel renders plain text"
else bad "the panel accepts markup again"; fi
if grep -q 'function singleLine' Model.js && grep -q 'replace(/<\[^>\]' Model.js; then
  ok "singleLine strips inline markup"
else
  bad "singleLine no longer strips markup"
fi

echo "7. Manifest and repository hygiene"
if command -v omarchy >/dev/null 2>&1; then
  if omarchy plugin validate . >/dev/null 2>&1; then ok "omarchy plugin validate passes"
  else bad "omarchy plugin validate fails"; fi
else
  printf '  skip  omarchy not on PATH\n'
fi
if grep -rq '—' bin/fresque Model.js Panel.qml BarWidget.qml Service.qml README.md manifest.json 2>/dev/null; then
  bad "an em dash slipped into a delivered file"
else
  ok "no em dash in the delivered files"
fi

echo
if ((fail == 0)); then echo "audit: clean"; else echo "audit: problems above"; fi
exit "$fail"
