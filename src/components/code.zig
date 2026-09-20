//! Code — Mantine's monospace inline chip and block.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const mono_font = "Noto Sans Mono, monospace";

pub fn monoText(value: []const u8, size: f32, color: zui.Color) zui.Element {
    return zui.text(value, .{ .font = mono_font, .size = size, .line_height = size + 6, .color = color });
}

pub const Code = struct {
    text: []const u8,
    block: bool = false,

    pub fn init(text: []const u8) Code {
        return .{ .text = text };
    }

    pub fn asBlock(self: Code) Code {
        var copy = self;
        copy.block = true;
        return copy;
    }

    pub fn render(self: Code) zui.Element {
        if (self.block) {
            return zui.div().flex_col().p(12).rounded_lg().bg(theme.secondary)
                .border_1().border_color(theme.border)
                .child(zui.text(self.text, .{
                .font = mono_font,
                .size = 13,
                .line_height = 20,
                .color = theme.body,
            }));
        }
        return zui.div().flex_row().items_center().px(6).h(20).rounded(6)
            .bg(theme.secondary)
            .child(zui.text(self.text, .{
            .font = mono_font,
            .size = 12,
            .line_height = 16,
            .color = theme.body,
        }));
    }
};

const std = @import("std");

test "mono token" {
    try std.testing.expect(mono_font.len > 0);
}
