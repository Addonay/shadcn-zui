//! Sheet — shadcn/ui's side/bottom panel that slides over the page.
//!
//! Same overlay mechanics as `dialog`: an `absolute().inset(0)` root
//! appended as the **last child of the app root**; a scrim child with an
//! optional dismiss listener; the panel is a later sibling so it paints on
//! top and blocks scrim clicks through `support.noopListener()`.
//!
//! zui has no `justify_end`, so side placement uses a `spacer` sibling.
//!
//! ```zig
//! if (self.sheet_open) page = page.child(
//!     Sheet.init(.right)
//!         .titleText("Edit profile")
//!         .content(form_element)
//!         .onScrimClick(cx.listener(State, closeSheet))
//!         .render(),
//! );
//! ```

const zui = @import("zui");

const dialog_component = @import("dialog.zig");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Side = enum { left, right, top, bottom };

/// shadcn sheet width (`sm` = 385px) and height.
pub const default_width: f32 = 385;
pub const default_height: f32 = 420;

pub const Sheet = struct {
    side: Side,
    title: []const u8 = "",
    description_value: ?[]const u8 = null,
    content_value: ?zui.Element = null,
    footer_value: ?zui.Element = null,
    width_px: f32 = default_width,
    height_px: f32 = default_height,
    on_scrim_click: ?zui.elements.Listener = null,

    pub fn init(side: Side) Sheet {
        return .{ .side = side };
    }

    pub fn titleText(self: Sheet, value: []const u8) Sheet {
        var copy = self;
        copy.title = value;
        return copy;
    }

    pub fn description(self: Sheet, value: ?[]const u8) Sheet {
        var copy = self;
        copy.description_value = value;
        return copy;
    }

    pub fn content(self: Sheet, value: zui.Element) Sheet {
        var copy = self;
        copy.content_value = value;
        return copy;
    }

    pub fn footer(self: Sheet, value: zui.Element) Sheet {
        var copy = self;
        copy.footer_value = value;
        return copy;
    }

    pub fn width(self: Sheet, px: f32) Sheet {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn height(self: Sheet, px: f32) Sheet {
        var copy = self;
        copy.height_px = px;
        return copy;
    }

    pub fn onScrimClick(self: Sheet, listener: zui.elements.Listener) Sheet {
        var copy = self;
        copy.on_scrim_click = listener;
        return copy;
    }

    /// The full-screen overlay. Append as the last child of the app root.
    pub fn render(self: Sheet) zui.Element {
        // The overlay direction follows the side so the spacer trick works.
        var overlay = switch (self.side) {
            .left, .right => zui.div().absolute().inset(0).flex_row(),
            .top, .bottom => zui.div().absolute().inset(0).flex_col(),
        };
        overlay = overlay.child(dialog_component.scrimLayer(self.on_scrim_click));

        // Full-height (left/right) or full-width (top/bottom) panel:
        // `size_full` then the explicit dimension overrides that axis.
        var panel = zui.div().size_full().flex_col().gap(16).p(24)
            .bg(theme.popover)
            .border_1().border_color(theme.border)
            .shadow_lg()
            .on_click(support.noopListener());
        panel = switch (self.side) {
            .left, .right => panel.w(self.width_px),
            .top, .bottom => panel.h(self.height_px),
        };

        var header = zui.div().flex_col().gap(4)
            .child(support.strong(self.title, 16, theme.foreground));
        if (self.description_value) |text| {
            header = header.child(support.label(text, 14, theme.muted_foreground));
        }
        panel = panel.child(header);
        if (self.content_value) |element| panel = panel.child(zui.div().flex_1().child(element));
        if (self.footer_value) |element| panel = panel.child(element);

        // Left/top: panel then spacer; right/bottom: spacer then panel
        // (zui has no justify_end; the flex_1 spacer pushes instead).
        return switch (self.side) {
            .left, .top => overlay.child(panel).child(zui.spacer()),
            .right, .bottom => overlay.child(zui.spacer()).child(panel),
        };
    }
};

const std = @import("std");

test "default geometry" {
    try std.testing.expectEqual(@as(f32, 385), default_width);
    try std.testing.expectEqual(@as(f32, 420), default_height);
}
