//! Icon component with swappable icon-pack presets.
//!
//! The default preset is **lucide** (1830 SVGs bundled from gpui-kit).
//! Build with `-Dicons-preset=tabler|phosphor|heroicons|hugeicons` to swap
//! the whole catalog: `tools/gen_icons.py --preset <name>` generates each
//! pack's names table over `assets/<preset>/*.svg`, and the comptime switch
//! below embeds ONLY the active pack's assets into the binary.
//!
//! ```zig
//! icon.render(.search, 16, theme.muted_foreground)
//! // or the builder:
//! Icon.init(.search).size(16).color(theme.muted_foreground).render()
//! ```

const zui = @import("zui");

const theme = @import("../../theme.zig");
const build_options = @import("build_options");

/// Which icon pack the binary links (lucide unless overridden at build time).
pub const Preset = @TypeOf(build_options.icons_preset);

/// Which icon pack the binary links (lucide unless overridden at build time).
pub const preset: Preset = build_options.icons_preset;

/// The active pack's generated module; unreferenced branches are not
/// analyzed, so inactive packs' assets never reach the binary.
const generated = switch (preset) {
    .lucide => @import("icons_lucide.zig"),
    .tabler => @import("icons_tabler.zig"),
    .phosphor => @import("icons_phosphor.zig"),
    .heroicons => @import("icons_heroicons.zig"),
    .hugeicons => @import("icons_hugeicons.zig"),
};

pub const Name = generated.IconName;
/// Semantic roles resolved to the ACTIVE pack's names. Components and apps
/// should reference `icon.semantic.close` rather than a pack-specific name.
pub const semantic = generated.semantic;
pub const bytes_table = &generated.bytes_table;
pub const default_icons = &generated.default_icons;
pub const isDefault = generated.isDefault;

/// SVG source for an icon.
pub fn bytes(name: Name) []const u8 {
    return generated.bytes(name);
}

/// A square, tinted icon element (the dashboard's `ui.icon`).
pub fn render(name: Name, size: f32, color: zui.Color) zui.Element {
    return zui.svg(bytes(name)).w(size).h(size).tint(color);
}

pub const Icon = struct {
    name: Name,
    size_px: f32 = 16,
    tint: ?zui.Color = null,

    pub fn init(name: Name) Icon {
        return .{ .name = name };
    }

    pub fn size(self: Icon, px: f32) Icon {
        var copy = self;
        copy.size_px = px;
        return copy;
    }

    pub fn color(self: Icon, value: zui.Color) Icon {
        var copy = self;
        copy.tint = value;
        return copy;
    }

    /// Render with `theme.foreground` when no explicit color was set.
    pub fn render(self: Icon) zui.Element {
        var element = zui.svg(bytes(self.name)).w(self.size_px).h(self.size_px);
        element = element.tint(self.tint orelse theme.foreground);
        return element;
    }
};

test "icon bytes resolve for the active preset" {
    const std = @import("std");
    try std.testing.expect(bytes(@fromBackingInt(@as(u16, 0))).len > 0);
}
