//! Badge — shadcn/ui's inline status pill.
//!
//! Mirrors shadcn's [`Badge`](https://ui.shadcn.com/docs/components/badge):
//! a fully rounded, single-line label in one of four variants, optionally
//! preceded by a 12px icon (the dashboard's delta badge).
//!
//! ```zig
//! Badge.init("New").variant(.secondary).size(.md).icon(.circle_check).render()
//! ```

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");

pub const Variant = enum { primary, secondary, destructive, outline };
pub const Size = enum { sm, md };

pub const Metrics = struct {
    height: f32,
    padding_x: f32,
    text: f32,
    icon: f32,
    gap: f32,
};

/// shadcn's badge starts at 20px tall; the dashboard delta pill is 22x8 with a
/// 12px glyph, so `md` keeps that rhythm and `sm` shrinks one step.
pub fn metrics(size: Size) Metrics {
    return switch (size) {
        .md => .{ .height = 22, .padding_x = 8, .text = 12, .icon = 12, .gap = 4 },
        .sm => .{ .height = 18, .padding_x = 6, .text = 11, .icon = 11, .gap = 3 },
    };
}

pub const Colors = struct {
    background: ?zui.Color,
    foreground: zui.Color,
    border: ?zui.Color,
};

pub fn colors(variant: Variant) Colors {
    return switch (variant) {
        .primary => .{
            .background = theme.primary,
            .foreground = theme.primary_foreground,
            .border = null,
        },
        .secondary => .{
            .background = theme.secondary,
            .foreground = theme.secondary_foreground,
            .border = null,
        },
        .destructive => .{
            .background = theme.destructive,
            .foreground = theme.destructive_foreground,
            .border = null,
        },
        .outline => .{
            .background = null,
            .foreground = theme.foreground,
            .border = theme.border,
        },
    };
}

pub const Badge = struct {
    text: []const u8,
    variant_value: Variant = .primary,
    size_value: Size = .md,
    icon_value: ?icon_component.Name = null,

    pub fn init(text: []const u8) Badge {
        return .{ .text = text };
    }

    pub fn variant(self: Badge, value: Variant) Badge {
        var copy = self;
        copy.variant_value = value;
        return copy;
    }

    pub fn size(self: Badge, value: Size) Badge {
        var copy = self;
        copy.size_value = value;
        return copy;
    }

    pub fn icon(self: Badge, name: icon_component.Name) Badge {
        var copy = self;
        copy.icon_value = name;
        return copy;
    }

    pub fn render(self: Badge) zui.Element {
        const m = metrics(self.size_value);
        const c = colors(self.variant_value);

        var badge = zui.div().flex_row().items_center()
            .h(m.height).px(m.padding_x).gap(m.gap).rounded_full();
        if (c.background) |value| badge = badge.bg(value);
        if (c.border) |value| badge = badge.border_1().border_color(value);

        if (self.icon_value) |name| {
            badge = badge.child(icon_component.render(name, m.icon, c.foreground));
        }
        return badge.child(support.strong(self.text, m.text, c.foreground));
    }
};

const std = @import("std");

test "metrics follow shadcn badge heights" {
    const md = metrics(.md);
    try std.testing.expectEqual(@as(f32, 22), md.height);
    try std.testing.expectEqual(@as(f32, 8), md.padding_x);
    try std.testing.expectEqual(@as(f32, 12), md.text);
    try std.testing.expectEqual(@as(f32, 12), md.icon);
    try std.testing.expectEqual(@as(f32, 4), md.gap);

    const sm = metrics(.sm);
    try std.testing.expectEqual(@as(f32, 18), sm.height);
    try std.testing.expectEqual(@as(f32, 6), sm.padding_x);
    try std.testing.expectEqual(@as(f32, 11), sm.text);
    try std.testing.expectEqual(@as(f32, 11), sm.icon);
    try std.testing.expectEqual(@as(f32, 3), sm.gap);
}

test "variants resolve expected colors" {
    const primary = colors(.primary);
    try std.testing.expectEqual(theme.primary, primary.background.?);
    try std.testing.expectEqual(theme.primary_foreground, primary.foreground);
    try std.testing.expect(primary.border == null);

    const secondary = colors(.secondary);
    try std.testing.expectEqual(theme.secondary, secondary.background.?);
    try std.testing.expectEqual(theme.secondary_foreground, secondary.foreground);

    const destructive = colors(.destructive);
    try std.testing.expectEqual(theme.destructive, destructive.background.?);
    try std.testing.expectEqual(theme.destructive_foreground, destructive.foreground);

    const outline = colors(.outline);
    try std.testing.expect(outline.background == null);
    try std.testing.expectEqual(theme.border, outline.border.?);
    try std.testing.expectEqual(theme.foreground, outline.foreground);
}
