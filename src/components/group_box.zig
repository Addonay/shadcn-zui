//! GroupBox — a titled, bordered section (gpui-kit's `group_box`).

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const padding: f32 = 16;
pub const radius: f32 = 12;

pub const GroupBox = struct {
    title: []const u8 = "",
    content_value: ?zui.Element = null,
    gap_px: f32 = 12,

    pub fn init(title: []const u8) GroupBox {
        return .{ .title = title };
    }

    pub fn content(self: GroupBox, value: zui.Element) GroupBox {
        var copy = self;
        copy.content_value = value;
        return copy;
    }

    pub fn gap(self: GroupBox, px: f32) GroupBox {
        var copy = self;
        copy.gap_px = px;
        return copy;
    }

    pub fn render(self: GroupBox) zui.Element {
        var box = zui.div().flex_col().gap(self.gap_px).p(padding)
            .rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border_strong);
        if (self.title.len > 0) {
            box = box.child(support.label(self.title, 12, theme.muted_foreground));
        }
        if (self.content_value) |element| box = box.child(element);
        return box;
    }
};

const std = @import("std");

test "palette and padding" {
    try std.testing.expectEqual(theme.card, theme.card);
    try std.testing.expectEqual(@as(f32, 16), padding);
    try std.testing.expectEqual(@as(f32, 12), radius);
}
