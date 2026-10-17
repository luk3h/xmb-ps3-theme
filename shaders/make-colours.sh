#!/usr/bin/env bash
# Builds a single-colour version of the wave for each palette colour, into shaders/colours/.
# Each one shows up in Shader Wallpaper's list (e.g. "xmb-wave-blue") and stays that colour all day.
# Needs Qt's shader compiler:  sudo dnf install qt6-qtshadertools
set -e
cd "$(dirname "$0")"
QSB="$(command -v qsb || true)"
for q in /usr/lib64/qt6/bin/qsb /usr/lib/qt6/bin/qsb /usr/lib/x86_64-linux-gnu/qt6/bin/qsb; do
    [ -z "$QSB" ] && [ -x "$q" ] && QSB="$q"
done
[ -n "$QSB" ] || { echo "qsb not found - install qt6-qtshadertools (Fedora) or qt6-shader-baker (Ubuntu)"; exit 1; }

mkdir -p colours
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
i=0
for name in blue purple pink red gold green teal grey; do     # same order as palette() in xmb-wave.frag
    sed "s/^#define FIXED_COLOUR -1/#define FIXED_COLOUR $i/" xmb-wave.frag > "$TMP/xmb-wave-$name.frag"
    "$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "colours/xmb-wave-$name.frag.qsb" "$TMP/xmb-wave-$name.frag"
    echo "built colours/xmb-wave-$name.frag.qsb"
    i=$((i + 1))
done
