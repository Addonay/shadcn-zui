//! ScrollArea — a clipped viewport with app-owned scroll offset.
//!
//! zui containers clip their children, and `scroll_y` translates the
//! content; the offset itself belongs to the app, driven by the wheel
//! through the scroll listener (see the dashboard's page scroll).
//!
//! ```zig
//! // state: scroll_offset: f32 = 0
//! ScrollArea.init(state.scroll_offset).height(300)
//!     .onScroll(cx.listener(State, onScroll))
//!     .content(whatever_list)
//!     .render()
//!
//! fn onScroll(state: *State, window: *zui.Window, cx: *zui.Context(State)) void {
//!     state.scroll_offset = ScrollArea.clamp(
//!         state.scroll_offset - window.scrollEvent().dy * 45,
//!         ScrollArea.contentHeight(ROWS.len, 52),
//!         300,
//!     );
//!     cx.notify();
//! }
//! ```

const zui = @import("zui");

const theme = @import("../theme.zig");

/// Clamp a scroll offset into `[0, content_h - viewport_h]` (pure).
pub fn clamp(offset: f32, content_height: f32, viewport_height: f32) f32 {
    const max = @max(0, content_height - viewport_height);
    return std.math.clamp(offset, 0, max);
}

/// Multiplier applied to wheel deltas (the dashboard's page speed).
pub const wheel_speed: f32 = 45;

pub const ScrollArea = struct {
    offset: f32 = 0,
    height_px: f32 = 300,
    content_value: ?zui.Element = null,
    listener: ?zui.Listener = null,
    border_value: bool = false,

    pub fn init(offset: f32) ScrollArea {
        return .{ .offset = offset };
    }

    pub fn height(self: ScrollArea, px: f32) ScrollArea {
        var copy = self;
        copy.height_px = px;
        return copy;
    }

    pub fn content(self: ScrollArea, value: zui.Element) ScrollArea {
        var copy = self;
        copy.content_value = value;
        return copy;
    }

    pub fn onScroll(self: ScrollArea, listener: zui.Listener) ScrollArea {
        var copy = self;
        copy.listener = listener;
        return copy;
    }

    pub fn border(self: ScrollArea, value: bool) ScrollArea {
        var copy = self;
        copy.border_value = value;
        return copy;
    }

    pub fn render(self: ScrollArea) zui.Element {
        var viewport = zui.div().w_full().h(self.height_px).scroll_y(self.offset);
        if (self.border_value) {
            viewport = viewport.rounded_lg().border_1().border_color(theme.border);
        }
        if (self.listener != null) {
            viewport = viewport.on_scroll(self.listener.?);
        }
        if (self.content_value) |element| {
            viewport = viewport.child(element);
        }
        return viewport;
    }
};

const std = @import("std");

test "clamp keeps offsets in range and allows overscroll-free bottom" {
    try std.testing.expectEqual(@as(f32, 0), clamp(-5, 1000, 300));
    try std.testing.expectEqual(@as(f32, 700), clamp(999, 1000, 300));
    try std.testing.expectEqual(@as(f32, 0), clamp(50, 100, 300));
    try std.testing.expectEqual(@as(f32, 42), clamp(42, 1000, 300));
}
