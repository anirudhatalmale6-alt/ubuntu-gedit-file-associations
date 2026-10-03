#!/bin/bash
# Make .h .hpp .cpp .c (and .cc/.cxx/.hh) open in gedit instead of notepad.
# Ubuntu 26.04 / GNOME. Safe to re-run. Backs up any file it edits.

MIMES="text/x-chdr text/x-c++hdr text/x-c++src text/x-csrc"
STAMP=$(date +%Y%m%d-%H%M%S)

echo "== 1. Finding gedit's .desktop file =="
GEDIT=""
for d in "$HOME/.local/share/applications" /usr/share/applications \
         /usr/local/share/applications /var/lib/snapd/desktop/applications; do
    [ -d "$d" ] || continue
    for f in "$d"/*gedit*.desktop; do
        [ -f "$f" ] || continue
        GEDIT=$(basename "$f"); echo "   found: $GEDIT   (in $d)"; break 2
    done
done
if [ -z "$GEDIT" ]; then
    echo "   ERROR: gedit is not installed. Run:  sudo apt install gedit"
    exit 1
fi

# gedit must actually be runnable, or xdg-mime silently ignores the setting
if ! command -v gedit >/dev/null 2>&1; then
    echo "   WARNING: '$GEDIT' exists but the gedit binary isn't in PATH."
    echo "            xdg-mime will silently ignore the change. Run: sudo apt install gedit"
fi

echo
echo "== 2. Clearing conflicting entries from higher-priority files =="
# On GNOME, ~/.config/gnome-mimeapps.list OVERRIDES ~/.config/mimeapps.list
for p in "$HOME/.config/gnome-mimeapps.list" \
         "$HOME/.local/share/applications/mimeapps.list"; do
    [ -f "$p" ] || continue
    if grep -qE '^(text/x-chdr|text/x-c\+\+hdr|text/x-c\+\+src|text/x-csrc)=' "$p"; then
        cp -a "$p" "$p.bak-$STAMP"
        echo "   editing $p  (backup: $p.bak-$STAMP)"
        sed -i -E '/^(text\/x-chdr|text\/x-c\+\+hdr|text\/x-c\+\+src|text\/x-csrc)=/d' "$p"
    else
        echo "   $p - nothing to clear"
    fi
done

echo
echo "== 3. Setting gedit as the default =="
for m in $MIMES; do xdg-mime default "$GEDIT" "$m"; echo "   set $m"; done

echo
echo "== 4. VERIFYING (the step that actually matters) =="
FAIL=0
for m in $MIMES; do
    GOT=$(xdg-mime query default "$m")
    if [ "$GOT" = "$GEDIT" ]; then printf "   OK      %-16s -> %s\n" "$m" "$GOT"
    else printf "   FAILED  %-16s -> %s  (wanted %s)\n" "$m" "${GOT:-<none>}" "$GEDIT"; FAIL=1; fi
done

echo
echo "== 5. Real-file check (files must be non-empty to sniff correctly) =="
TD=$(mktemp -d)
for ext in h hpp cpp c cc cxx hh; do
    T="$TD/check.$ext"; printf '#pragma once\nint v;\n' > "$T"
    MT=$(xdg-mime query filetype "$T")
    printf "   .%-4s %-14s -> %s\n" "$ext" "$MT" "$(xdg-mime query default "$MT")"
done
rm -rf "$TD"

echo
if [ "$FAIL" -eq 0 ]; then
    echo "SUCCESS - your .h/.hpp/.cpp files will now open in gedit."
    echo "If Files/Nautilus still shows notepad, log out and back in once."
else
    echo "STILL FAILING - send me the output above and I'll take it from there."
fi
