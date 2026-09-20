#!/usr/bin/env python3
"""Generate `src/components/icon/icons_generated.zig` from the asset files.

Mirrors gpui-kit's `build.rs` (crates/assets): every `assets/icons/*.svg`
kebab-case filename becomes a CamelCase-ish Zig enum variant, and the file
bytes are embedded through a table so lookups are O(1) at runtime.

The default set (gpui-kit's `default-icons.txt`) is exposed separately so
apps can tell curated assets from the full Lucide catalog.

Usage:
    python3 tools/gen_icons.py                    # lucide (default preset)
    python3 tools/gen_icons.py --preset tabler    # one per icon pack

Each preset writes `src/components/icon/icons_<preset>.zig` over
`src/components/icon/assets/<preset>/*.svg` with the same interface
(`IconName`, `count`, `bytes_table`, `bytes(name)`, `default_icons`,
`isDefault`). Only the ACTIVE preset is embedded in a build (see
build.zig's `-Dicons-preset`); the others stay out of the binary.

Run from the repo root (or pass --root); exits non-zero on any problem so
it can be wired into CI.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ZIG_KEYWORDS = {
    "addrspace", "align", "allowzero", "and", "anyframe", "anytype", "asm",
    "async", "await", "break", "callconv", "catch", "comptime", "const",
    "continue", "defer", "else", "enum", "errdefer", "error", "export",
    "extern", "fn", "for", "if", "inline", "linksection", "noalias",
    "noinline", "nosuspend", "opaque", "or", "orelse", "packed", "pub",
    "resume", "return", "struct", "suspend", "switch", "test", "threadlocal",
    "try", "union", "unreachable", "usingnamespace", "var", "volatile",
    "while",
}


# Semantic icon roles: the stable names the library and apps use.
# Each pack maps a role to its own equivalent glyph (verified stems).
SEMANTIC = {
    "loader": {"lucide": "loader", "tabler": "loader_2", "phosphor": "spinner", "heroicons": "arrow_path", "hugeicons": "loader"},
    "app_window": {"lucide": "app_window", "tabler": "app_window", "phosphor": "app_window", "heroicons": "cube", "hugeicons": "app_window"},
    "arrow_down": {"lucide": "arrow_down", "tabler": "arrow_down", "phosphor": "arrow_down", "heroicons": "arrow_down", "hugeicons": "arrow_down01"},
    "arrow_up": {"lucide": "arrow_up", "tabler": "arrow_up", "phosphor": "arrow_up", "heroicons": "arrow_up", "hugeicons": "arrow_up01"},
    "bell": {"lucide": "bell", "tabler": "bell", "phosphor": "bell", "heroicons": "bell", "hugeicons": "bell"},
    "book_open": {"lucide": "book_open", "tabler": "book", "phosphor": "book_open", "heroicons": "book_open", "hugeicons": "book01"},
    "chart_pie": {"lucide": "chart_pie", "tabler": "chart_pie", "phosphor": "chart_pie", "heroicons": "chart_pie", "hugeicons": "pie_chart01"},
    "check": {"lucide": "check", "tabler": "check", "phosphor": "check", "heroicons": "check", "hugeicons": "check"},
    "chevron_down": {"lucide": "chevron_down", "tabler": "chevron_down", "phosphor": "caret_down", "heroicons": "chevron_down", "hugeicons": "chevron_down"},
    "chevron_left": {"lucide": "chevron_left", "tabler": "chevron_left", "phosphor": "caret_left", "heroicons": "chevron_left", "hugeicons": "chevron_left"},
    "chevron_right": {"lucide": "chevron_right", "tabler": "chevron_right", "phosphor": "caret_right", "heroicons": "chevron_right", "hugeicons": "chevron_right"},
    "chevron_up": {"lucide": "chevron_up", "tabler": "chevron_up", "phosphor": "caret_up", "heroicons": "chevron_up", "hugeicons": "chevron_up"},
    "info": {"lucide": "info", "tabler": "info_circle", "phosphor": "info", "heroicons": "information_circle", "hugeicons": "information_circle"},
    "alert": {"lucide": "triangle_alert", "tabler": "alert_triangle", "phosphor": "warning", "heroicons": "exclamation_triangle", "hugeicons": "alert01"},
    "success": {"lucide": "circle_check", "tabler": "circle_check", "phosphor": "check_circle", "heroicons": "check_circle", "hugeicons": "circle_check"},
    "error_state": {"lucide": "circle_x", "tabler": "circle_x", "phosphor": "x_circle", "heroicons": "x_mark", "hugeicons": "x"},
    "close": {"lucide": "x", "tabler": "x", "phosphor": "x", "heroicons": "x_mark", "hugeicons": "x"},
    "copy": {"lucide": "copy", "tabler": "copy", "phosphor": "copy", "heroicons": "clipboard_document", "hugeicons": "copy01"},
    "ellipsis_vertical": {"lucide": "ellipsis_vertical", "tabler": "dots_vertical", "phosphor": "dots_three_vertical", "heroicons": "ellipsis_vertical", "hugeicons": "more01"},
    "external_link": {"lucide": "external_link", "tabler": "external_link", "phosphor": "arrow_square_out", "heroicons": "arrow_top_right_on_square", "hugeicons": "link01"},
    "file": {"lucide": "file_text", "tabler": "file_text", "phosphor": "file_text", "heroicons": "document_text", "hugeicons": "file_text"},
    "file_image": {"lucide": "image", "tabler": "photo", "phosphor": "image", "heroicons": "photo", "hugeicons": "image01"},
    "archive": {"lucide": "folder_archive", "tabler": "file_zip", "phosphor": "archive", "heroicons": "archive_box", "hugeicons": "folder_archive"},
    "audio": {"lucide": "music", "tabler": "music", "phosphor": "music_notes", "heroicons": "musical_note", "hugeicons": "music"},
    "video": {"lucide": "video", "tabler": "video", "phosphor": "video_camera", "heroicons": "video_camera", "hugeicons": "camera_video"},
    "paperclip": {"lucide": "paperclip", "tabler": "paperclip", "phosphor": "paperclip", "heroicons": "paper_clip", "hugeicons": "attachment"},
    "folder": {"lucide": "folder", "tabler": "folder", "phosphor": "folder", "heroicons": "folder", "hugeicons": "folder01"},
    "house": {"lucide": "house", "tabler": "home", "phosphor": "house", "heroicons": "home", "hugeicons": "home01"},
    "layout_dashboard": {"lucide": "layout_dashboard", "tabler": "layout_dashboard", "phosphor": "layout", "heroicons": "squares_2x2", "hugeicons": "dashboard_circle"},
    "layout_panel_left": {"lucide": "layout_panel_left", "tabler": "layout_sidebar", "phosphor": "sidebar", "heroicons": "window", "hugeicons": "sidebar_left"},
    "mail": {"lucide": "mail", "tabler": "mail", "phosphor": "envelope", "heroicons": "envelope", "hugeicons": "mail01"},
    "palette": {"lucide": "palette", "tabler": "palette", "phosphor": "palette", "heroicons": "swatch", "hugeicons": "palette"},
    "plus": {"lucide": "plus", "tabler": "plus", "phosphor": "plus", "heroicons": "plus", "hugeicons": "plus"},
    "search": {"lucide": "search", "tabler": "search", "phosphor": "magnifying_glass", "heroicons": "magnifying_glass", "hugeicons": "search01"},
    "settings": {"lucide": "settings", "tabler": "settings", "phosphor": "gear", "heroicons": "adjustments_horizontal", "hugeicons": "setting06"},
    "share": {"lucide": "share", "tabler": "share", "phosphor": "share_network", "heroicons": "share", "hugeicons": "share01"},
    "square_mouse_pointer": {"lucide": "square_mouse_pointer", "tabler": "pointer", "phosphor": "cursor_click", "heroicons": "cursor_arrow_rays", "hugeicons": "cursor01"},
    "table": {"lucide": "table", "tabler": "table", "phosphor": "table", "heroicons": "table_cells", "hugeicons": "table01"},
    "terminal": {"lucide": "terminal", "tabler": "terminal", "phosphor": "terminal_window", "heroicons": "command_line", "hugeicons": "terminal"},
    "text_cursor": {"lucide": "text_cursor", "tabler": "cursor_text", "phosphor": "cursor_text", "heroicons": "pencil_square", "hugeicons": "input_cursor_text"},
    "trash": {"lucide": "trash", "tabler": "trash", "phosphor": "trash", "heroicons": "trash", "hugeicons": "delete01"},
    "trending_up": {"lucide": "trending_up", "tabler": "trending_up", "phosphor": "trend_up", "heroicons": "arrow_trending_up", "hugeicons": "trending_up"},
    "trending_down": {"lucide": "trending_down", "tabler": "trending_down", "phosphor": "trend_down", "heroicons": "arrow_trending_down", "hugeicons": "trending_down"},
    "database": {"lucide": "database", "tabler": "database", "phosphor": "database", "heroicons": "circle_stack", "hugeicons": "database"},
    "compass": {"lucide": "compass", "tabler": "compass", "phosphor": "compass", "heroicons": "globe_alt", "hugeicons": "compass"},
}

def zig_ident(stem: str) -> str:
    """kebab-case file stem -> snake_case Zig identifier (quoted if needed)."""
    ident = stem.replace("-", "_").replace(".", "_")
    if ident in ZIG_KEYWORDS:
        return f'@"{ident}"'
    if ident and ident[0].isdigit():
        ident = "n" + ident
    return ident


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--check", action="store_true", help="fail if output is stale")
    parser.add_argument(
        "--preset",
        default="lucide",
        choices=["lucide", "tabler", "phosphor", "heroicons", "hugeicons"],
        help="icon pack to generate a names table for",
    )
    args = parser.parse_args()

    root = args.root
    preset = args.preset
    icon_root = root / "src" / "components" / "icon"
    icons_dir = icon_root / "assets" / preset
    defaults_file = icon_root / "assets" / "default-icons.txt"
    out_file = icon_root / f"icons_{preset}.zig"
    embed_dir = f"assets/{preset}"
    embed_prefix = f"assets/{preset}"

    if not icons_dir.is_dir():
        print(f"error: missing icon assets: {icons_dir}", file=sys.stderr)
        return 1

    files = sorted(icons_dir.glob("*.svg"))
    if not files:
        print(f"error: no SVG files in {icons_dir}", file=sys.stderr)
        return 1

    seen: dict[str, str] = {}
    entries: list[tuple[str, str]] = []  # (zig ident, file stem)
    for path in files:
        ident = zig_ident(path.stem)
        if ident in seen:
            print(f"error: name collision: {path.stem} and {seen[ident]} -> {ident}", file=sys.stderr)
            return 1
        seen[ident] = path.stem
        entries.append((ident, path.stem))

    default_stems: list[str] = []
    if preset == "lucide" and defaults_file.is_file():
        for line in defaults_file.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            default_stems.append(Path(line).stem)
    known = {stem for _, stem in entries}
    defaults = [s for s in default_stems if s in known]

    lines: list[str] = []
    preset_label = {
        "lucide": "Lucide icons copied from gpui-kit (crates/assets/assets/icons)",
        "tabler": "Tabler icons (outline weight, MIT)",
        "phosphor": "Phosphor icons (regular weight, MIT)",
        "heroicons": "Heroicons (outline weight, MIT)",
        "hugeicons": "HugeIcons (free stroke set)",
    }[preset]
    lines.append("//! GENERATED by tools/gen_icons.py -- do not edit by hand.")
    lines.append("//!")
    lines.append(f"//! {len(entries)} {preset_label}.")
    lines.append("")
    lines.append("const std = @import(\"std\");")
    lines.append("")
    lines.append("/// Every icon in this pack.")
    lines.append("pub const IconName = enum {")
    for ident, _ in entries:
        lines.append(f"    {ident},")
    lines.append("};")
    lines.append("")
    lines.append(f"pub const count = {len(entries)};")
    lines.append("")
    lines.append("/// SVG bytes indexed by the backing integer.")
    lines.append("pub const bytes_table = [count][]const u8{")
    for ident, stem in entries:
        lines.append(f'    @embedFile("{embed_dir}/{stem}.svg"),')
    lines.append("};")
    lines.append("")
    lines.append("/// SVG source for an icon.")
    lines.append("pub fn bytes(name: IconName) []const u8 {")
    lines.append("    return bytes_table[@backingInt(name)];")
    lines.append("}")
    lines.append("")
    lines.append("/// Semantic roles -> this pack's names (apps write `semantic.close`).")
    lines.append("pub const semantic = struct {")
    for role, per in SEMANTIC.items():
        stem = per.get(preset) or per["lucide"]
        lines.append(f"    pub const {role} = IconName.{zig_ident(stem)};")
    lines.append("};")
    lines.append("")
    lines.append("/// The curated default set (Lucide only; empty for other packs).")
    lines.append("pub const default_icons = [_]IconName{")
    for stem in defaults:
        lines.append(f"    .{zig_ident(stem)},")
    lines.append("};")
    lines.append("")
    lines.append("/// True when the icon ships in the default curated set.")
    lines.append("pub fn isDefault(name: IconName) bool {")
    lines.append("    for (default_icons) |candidate| {")
    lines.append("        if (candidate == name) return true;")
    lines.append("    }")
    lines.append("    return false;")
    lines.append("}")
    lines.append("")
    if preset == "lucide":
        lines.append("test \"icon table is consistent\" {")
        lines.append("    try std.testing.expectEqual(count, bytes_table.len);")
        lines.append("    try std.testing.expect(default_icons.len > 0);")
        lines.append("    try std.testing.expect(isDefault(.arrow_down));")
        lines.append("    try std.testing.expect(!isDefault(.air_vent));")
        lines.append("}")
    else:
        lines.append("test \"icon table is consistent\" {")
        lines.append("    try std.testing.expectEqual(count, bytes_table.len);")
        lines.append("}")
    lines.append("")
    content = "\n".join(lines)

    if args.check:
        current = out_file.read_text() if out_file.is_file() else ""
        if current != content:
            print(f"stale: {out_file} (run python3 tools/gen_icons.py)", file=sys.stderr)
            return 1
        print(f"ok: {out_file} is up to date ({len(entries)} icons)")
        return 0

    out_file.write_text(content)
    print(f"wrote {out_file}: {len(entries)} icons, {len(defaults)} defaults")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
