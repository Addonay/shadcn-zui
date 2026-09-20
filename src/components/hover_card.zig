//! HoverCard — shadcn/Mantine's preview card. Rendered through the app root
//! like Popover; apps trigger it on hover (or click) and anchor the point.

const zui = @import("zui");

const theme = @import("../theme.zig");
const popover_component = @import("popover.zig");

pub const HoverCard = struct {
    inner: popover_component.Popover,

    pub fn init(x: f32, y: f32) HoverCard {
        return .{ .inner = popover_component.Popover.init(x, y) };
    }

    pub fn at(self: HoverCard, x: f32, y: f32) HoverCard {
        var copy = self;
        copy.inner = copy.inner.at(x, y);
        return copy;
    }

    pub fn width(self: HoverCard, px: f32) HoverCard {
        var copy = self;
        copy.inner = copy.inner.width(px);
        return copy;
    }

    pub fn content(self: HoverCard, element: zui.Element) HoverCard {
        var copy = self;
        copy.inner = copy.inner.content(element);
        return copy;
    }

    pub fn onScrimClick(self: HoverCard, listener: zui.Listener) HoverCard {
        var copy = self;
        copy.inner = copy.inner.onScrimClick(listener);
        return copy;
    }

    pub fn render(self: HoverCard) zui.Element {
        return self.inner.render();
    }
};

const std = @import("std");

test "defaults" {
    try std.testing.expectEqual(popover_component.default_width, (HoverCard.init(0, 0).inner.width_px));
}
