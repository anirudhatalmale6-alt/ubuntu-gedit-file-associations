# Make .h / .hpp / .cpp open in gedit on Ubuntu (GNOME)

If you installed another editor ("notepad") and it hijacked your C/C++ files,
this restores gedit as the default.

## Quick fix

```bash
wget https://raw.githubusercontent.com/anirudhatalmale6-alt/ubuntu-gedit-file-associations/main/fix-gedit-assoc.sh
chmod +x fix-gedit-assoc.sh
./fix-gedit-assoc.sh
```

Safe to re-run. It backs up any file it edits.

## Why the obvious command often doesn't work

```bash
xdg-mime default org.gnome.gedit.desktop text/x-chdr
```

This **exits 0 and prints no error even when it does nothing**. Two reasons:

1. **Wrong .desktop filename.** It differs by install method
   (`org.gnome.gedit.desktop`, `gedit.desktop`, `gedit_gedit.desktop` for snap).
   If the name doesn't resolve to an installed binary, the setting is silently ignored.
2. **`~/.config/gnome-mimeapps.list` overrides `~/.config/mimeapps.list`** on GNOME.
   `xdg-mime` writes to the second one, so a stale entry in the first keeps winning.

Always verify:

```bash
xdg-mime query default text/x-chdr
```

## MIME types involved

| Extension      | MIME type        |
|----------------|------------------|
| `.h`           | `text/x-chdr`    |
| `.hpp` `.hh`   | `text/x-c++hdr`  |
| `.cpp` `.cc` `.cxx` | `text/x-c++src` |
| `.c`           | `text/x-csrc`    |

Note: `xdg-mime query filetype` on a **zero-byte** file returns
`application/x-zerosize`, not the type above. Test with a non-empty file.
