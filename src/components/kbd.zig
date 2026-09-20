//! Kbd — a keyboard key chip (gpui-kit's `kbd`).

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const height: f32 = 20;
pub const padding_x: f32 = 6;
pub const radius: f32 = 4;
pub const text_size: f32 = 11;

pub const Style = struct {
    background: zui.Color,
    border: zui.Color,
    foreground: zui.Color,
};

pub fn style() Style {
    return .{ .background = theme.secondary, .border = theme.border_strong, .foreground = theme.muted_foreground };
}

fn chip(key: []const u8) zui.Element {
    const s = style();
    return zui.div().flex_row().items_center().justify_center()
        .h(height).px(padding_x).rounded(radius)
        .bg(s.background).border_1().border_color(s.border)
        .child(zui.text(key, .{
        .font = theme.font,
        .size = text_size,
        .line_height = text_size + 4,
        .weight = .medium,
        .color = s.foreground,
    }));
}

pub const Kbd = struct {
    key: []const u8,

    pub fn init(key: []const u8) Kbd {
        return .{ .key = key };
    }

    pub fn render(self: Kbd) zui.Element {
        return chip(self.key);
    }
};

/// A row of key chips, e.g. `row(&.{ "⌘", "K" })`.
pub fn row(keys: []const []const u8) zui.Element {
    var container = zui.div().flex_row().items_center().gap(4);
    for (keys) |key| {
        container = container.child(chip(key));
    }
    return container;
}

const std = @import("std");

test "chip metrics" {
    const s = style();
    try std.testing.expectEqual(theme.secondary, s.background);
    try std.testing.expectEqual(theme.border_strong, s.border);
    try std.testing.expectEqual(@as(f32, 20), height);
}
