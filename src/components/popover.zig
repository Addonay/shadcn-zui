//! Popover — shadcn/ui's floating panel, anchored at a window point.
//!
//! zui clips children to their parent, so a popover anchored inside a card
//! would be cut off. Like dialog/sheet, this renders a full-screen overlay
//! root to be appended as the **last child of the app root**, with the panel
//! absolutely positioned at `at(x, y)` — typically the pointer position (or
//! an anchor point the app tracks) at open time.
//!
//! ```zig
//! if (self.popover_open) page = page.child(
//!     Popover.init(self.popover_x, self.popover_y)
//!         .width(300)
//!         .content(panel_body)
//!         .onScrimClick(cx.listener(State, closePopover))
//!         .render(),
//! );
//! ```

const zui = @import("zui");

const dialog_component = @import("dialog.zig");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const default_width: f32 = 300;

/// Distance from the anchor point to the panel edge.
pub const anchor_gap: f32 = 6;

pub const Popover = struct {
    anchor_x: f32,
    anchor_y: f32,
    width_px: f32 = default_width,
    content_value: ?zui.Element = null,
    on_scrim_click: ?zui.Listener = null,

    pub fn init(x: f32, y: f32) Popover {
        return .{ .anchor_x = x, .anchor_y = y };
    }

    pub fn width(self: Popover, px: f32) Popover {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn content(self: Popover, value: zui.Element) Popover {
        var copy = self;
        copy.content_value = value;
        return copy;
    }

    /// Dismiss-on-outside-click. Without it the overlay is non-modal: no
    /// scrim is drawn and clicks pass through to the page below.
    pub fn onScrimClick(self: Popover, listener: zui.Listener) Popover {
        var copy = self;
        copy.on_scrim_click = listener;
        return copy;
    }

    /// The full-screen overlay. Append as the last child of the app root.
    pub fn render(self: Popover) zui.Element {
        var overlay = zui.div().absolute().inset(0);
        if (self.on_scrim_click != null) {
            overlay = overlay.child(dialog_component.scrimLayer(self.on_scrim_click));
        }

        var panel = zui.div().absolute()
            .left(self.anchor_x + anchor_gap)
            .top(self.anchor_y + anchor_gap)
            .w(self.width_px)
            .flex_col().gap(8).p(16)
            .rounded_lg().bg(theme.popover)
            .border_1().border_color(theme.border)
            .shadow_lg()
            .on_click(support.noopListener());
        if (self.content_value) |element| panel = panel.child(element);

        return overlay.child(panel);
    }
};

const std = @import("std");

test "defaults" {
    try std.testing.expectEqual(@as(f32, 300), default_width);
    try std.testing.expectEqual(@as(f32, 6), anchor_gap);
}
