//! Resizable — shadcn/gpui-kit's horizontal splitter. The app owns the
//! split fraction and drives it from the divider's pointer events
//! (wire it exactly like the slider thumb: on_mouse_down -> capture, then
//! move events update the fraction).

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const divider_width: f32 = 6;

/// Left pane width for a container width and split fraction (pure).
pub fn leftWidth(container_px: f32, fraction: f32) f32 {
    const clamped = std.math.clamp(fraction, 0, 1);
    const usable = @max(0, container_px - divider_width);
    return usable * clamped;
}

pub const Resizable = struct {
    /// Left / right pane elements — frame-local, set during render.
    left_value: zui.Element,
    right_value: zui.Element,
    fraction_value: f32 = 0.3,
    container_px: f32 = 900,
    on_divider_down: ?zui.Listener = null,
    on_divider_move: ?zui.Listener = null,
    on_divider_up: ?zui.Listener = null,

    pub fn init(left: zui.Element, right: zui.Element) Resizable {
        return .{ .left_value = left, .right_value = right };
    }

    pub fn fraction(self: Resizable, value: f32) Resizable {
        var copy = self;
        copy.fraction_value = value;
        return copy;
    }

    pub fn containerWidth(self: Resizable, px: f32) Resizable {
        var copy = self;
        copy.container_px = px;
        return copy;
    }

    pub fn onDividerDown(self: Resizable, listener: zui.Listener) Resizable {
        var copy = self;
        copy.on_divider_down = listener;
        return copy;
    }

    pub fn onDividerMove(self: Resizable, listener: zui.Listener) Resizable {
        var copy = self;
        copy.on_divider_move = listener;
        return copy;
    }

    pub fn onDividerUp(self: Resizable, listener: zui.Listener) Resizable {
        var copy = self;
        copy.on_divider_up = listener;
        return copy;
    }

    pub fn render(self: Resizable) zui.Element {
        var divider = zui.div().w(divider_width).h_full()
            .flex_col().items_center().justify_center()
            .bg(theme.border).rounded_full()
            .child(zui.div().w(2).h_full().rounded_full().bg(theme.border_strong));
        divider = divider.cursor_pointer();
        if (self.on_divider_down) |listener| divider = divider.on_mouse_down(listener);
        if (self.on_divider_move) |listener| divider = divider.on_mouse_move(listener);
        if (self.on_divider_up) |listener| divider = divider.on_mouse_up(listener);
        return zui.div().flex_row().w(self.container_px)
            .child(zui.div().w(leftWidth(self.container_px, self.fraction_value)).child(self.left_value))
            .child(divider)
            .child(zui.div().flex_1().child(self.right_value));
    }
};

test "left width math" {
    try std.testing.expectEqual(@as(f32, 268.2), leftWidth(900, 0.3));
    try std.testing.expectEqual(@as(f32, 0), leftWidth(900, -1));
    try std.testing.expectEqual(@as(f32, 894), leftWidth(900, 1));
}
