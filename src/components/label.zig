//! Label — shadcn/ui's form label (font medium, muted).

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const text_size: f32 = 14;
pub const line_height: f32 = 20;

/// Label color: muted normally, destructive for field errors.
pub fn colorFor(error_state: bool) zui.Color {
    return if (error_state) theme.destructive else theme.muted_foreground;
}

pub const Label = struct {
    text_value: []const u8 = "",
    error_value: bool = false,
    size_px: f32 = text_size,

    pub fn init(text: []const u8) Label {
        return .{ .text_value = text };
    }

    pub fn @"error"(self: Label, value: bool) Label {
        var copy = self;
        copy.error_value = value;
        return copy;
    }

    pub fn size(self: Label, px: f32) Label {
        var copy = self;
        copy.size_px = px;
        return copy;
    }

    pub fn render(self: Label) zui.Element {
        return zui.text(self.text_value, .{
            .font = theme.font,
            .size = self.size_px,
            .line_height = self.size_px + 6,
            .weight = .medium,
            .color = colorFor(self.error_value),
        });
    }
};

const std = @import("std");

test "error labels use the destructive token" {
    try std.testing.expectEqual(theme.muted_foreground, colorFor(false));
    try std.testing.expectEqual(theme.destructive, colorFor(true));
}
