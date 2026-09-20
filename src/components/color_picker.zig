//! ColorPicker — gpui-kit/Ant/Mantine's swatch grid + hex readout.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");

pub const swatch_px: f32 = 24;

/// Default swatch palette (dark-theme friendly).
pub const palette = [_]zui.Color{
    theme.background, theme.secondary, theme.ring,    theme.body,
    theme.foreground, theme.primary,   theme.chart_1, theme.chart_2,
    theme.chart_3,    theme.success,   theme.warning, theme.destructive,
};

/// "#RRGGBB" into the caller's buffer (pure; unit-tested).
pub fn hexLabel(color: zui.Color, buf: []u8) []const u8 {
    return std.fmt.bufPrint(buf, "#{x:0>2}{x:0>2}{x:0>2}", .{
        @as(u8, @intFromFloat(color.r * 255.0)),
        @as(u8, @intFromFloat(color.g * 255.0)),
        @as(u8, @intFromFloat(color.b * 255.0)),
    }) catch "";
}

pub const ColorPicker = struct {
    /// Currently selected color (matched against the palette).
    selected: ?zui.Color = null,
    /// Formatted hex label; borrowed until paint.
    hex_text: []const u8 = "",
    on_select: ?zui.Listener = null,

    pub fn init() ColorPicker {
        return .{};
    }

    pub fn selectedColor(self: ColorPicker, color: zui.Color) ColorPicker {
        var copy = self;
        copy.selected = color;
        return copy;
    }

    pub fn hex(self: ColorPicker, text: []const u8) ColorPicker {
        var copy = self;
        copy.hex_text = text;
        return copy;
    }

    pub fn onSelect(self: ColorPicker, listener: zui.Listener) ColorPicker {
        var copy = self;
        copy.on_select = listener;
        return copy;
    }

    pub fn render(self: ColorPicker) zui.Element {
        var panel = zui.div().flex_col().gap(10).p(12)
            .rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border)
            .child(support.label("Preset colors", 12, theme.muted_foreground));
        var grid = zui.div().flex_row().flex_wrap().gap(8).w(swatch_px * 6 + 10);
        for (palette) |color| {
            const is_selected = if (self.selected) |value| sameColor(value, color) else false;
            var swatch = zui.div().size(swatch_px).rounded(6)
                .bg(color)
                .border_1().border_color(if (is_selected) theme.foreground else theme.border);
            if (self.on_select != null) {
                swatch = swatch.cursor_pointer().hover_bg(theme.accent_hover);
            }
            if (self.on_select) |listener| {
                swatch = swatch.on_click(listener);
            }
            grid = grid.child(swatch);
        }
        panel = panel.child(grid);
        if (self.hex_text.len > 0) {
            panel = panel.child(zui.div().flex_row().items_center().gap(8)
                .child(zui.div().size(swatch_px).rounded(6).bg(self.selected orelse theme.secondary)
                    .border_1().border_color(theme.border))
                .child(support.label(self.hex_text, 13, theme.body)));
        }
        return panel;
    }
};

fn sameColor(a: zui.Color, b: zui.Color) bool {
    return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a;
}

test "hex label" {
    var buf: [8]u8 = undefined;
    const text = hexLabel(zui.hex(0xff0000), &buf);
    try std.testing.expectEqualStrings("#ff0000", text);
    try std.testing.expectEqual(@as(usize, 7), hexLabel(zui.hex(0x12abef), &buf).len);
}
