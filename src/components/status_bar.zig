//! StatusBar — gpui-kit's bottom bar with left/center/right regions.

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const height_px: f32 = 28;

pub const StatusBar = struct {
    /// Left / center / right region elements — frame-local, set during render.
    left_value: ?zui.Element = null,
    center_value: ?zui.Element = null,
    right_value: ?zui.Element = null,
    height_value: f32 = height_px,

    pub fn init() StatusBar {
        return .{};
    }

    pub fn left(self: StatusBar, element: zui.Element) StatusBar {
        var copy = self;
        copy.left_value = element;
        return copy;
    }

    pub fn center(self: StatusBar, element: zui.Element) StatusBar {
        var copy = self;
        copy.center_value = element;
        return copy;
    }

    pub fn right(self: StatusBar, element: zui.Element) StatusBar {
        var copy = self;
        copy.right_value = element;
        return copy;
    }

    pub fn height(self: StatusBar, px: f32) StatusBar {
        var copy = self;
        copy.height_value = px;
        return copy;
    }

    pub fn render(self: StatusBar) zui.Element {
        var bar = zui.div().flex_row().items_center().gap(12).h(self.height_value)
            .px(12).bg(theme.page)
            .border_t_1().border_color(theme.border);
        if (self.left_value) |element| bar = bar.child(element);
        if (self.center_value) |element| {
            bar = bar.child(zui.spacer()).child(element).child(zui.spacer());
        } else {
            bar = bar.child(zui.spacer());
        }
        if (self.right_value) |element| bar = bar.child(element);
        return bar;
    }
};

const std = @import("std");

test "default height" {
    try std.testing.expectEqual(@as(f32, 28), height_px);
}
