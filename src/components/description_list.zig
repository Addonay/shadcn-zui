//! DescriptionList — shadcn/ui's term/description rows.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const term_width: f32 = 120;
pub const row_gap: f32 = 10;

pub const Item = struct {
    term: []const u8 = "",
    description: []const u8 = "",
};

pub const DescriptionList = struct {
    items: []const Item,
    term_px: f32 = term_width,

    pub fn init(items: []const Item) DescriptionList {
        return .{ .items = items };
    }

    pub fn termWidth(self: DescriptionList, px: f32) DescriptionList {
        var copy = self;
        copy.term_px = px;
        return copy;
    }

    pub fn render(self: DescriptionList) zui.Element {
        var list = zui.div().flex_col().gap(row_gap);
        for (self.items) |item| {
            list = list.child(zui.div().flex_row().gap(16)
                .child(zui.div().w(self.term_px).child(support.label(item.term, 14, theme.muted_foreground)))
                .child(zui.div().flex_1().child(support.label(item.description, 14, theme.foreground))));
        }
        return list;
    }
};

const std = @import("std");

test "metrics" {
    try std.testing.expectEqual(@as(f32, 120), term_width);
    try std.testing.expectEqual(@as(f32, 10), row_gap);
}
