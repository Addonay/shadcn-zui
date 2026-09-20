//! Tooltip — shadcn/ui's hint bubble, anchored at a window point.
//!
//! zui clips children to their parent and cannot measure text before
//! layout, so a tooltip can't wrap itself around a target inline. Instead
//! the app renders the bubble as an **absolute element at the pointer
//! position** (or a tracked anchor), appended near the root like other
//! overlays. The bubble's width is estimated from its text for centering.
//!
//! ```zig
//! // hover state comes from the app (e.g. on_mouse_move sets the anchor):
//! if (self.tooltip_open) page = page.child(
//!     Tooltip.init("Add to favorites").at(self.tip_x, self.tip_y)
//!         .position(.bottom).render(),
//! );
//! ```

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Position = enum { top, bottom, left, right };

pub const bubble_height: f32 = 24;
pub const bubble_padding_x: f32 = 12;
/// Gap between the anchor point and the bubble edge.
pub const anchor_gap: f32 = 8;
/// Rough glyph advance for width estimation (Noto Sans at 12px).
pub const glyph_width: f32 = 6.6;

/// Estimated bubble width for `text` (padding + glyphs, capped).
pub fn estimateWidth(text: []const u8) f32 {
    const glyphs = @as(f32, @floatFromInt(text.len)) * glyph_width;
    return glyphs + bubble_padding_x * 2;
}

/// Pure anchor math: where the bubble's top-left corner goes for an anchor
/// at (x, y) with the bubble placed at `position`.
pub fn bubbleOrigin(text: []const u8, position: Position, x: f32, y: f32) struct { left: f32, top: f32 } {
    const w = estimateWidth(text);
    return switch (position) {
        .bottom => .{ .left = x - w / 2, .top = y + anchor_gap },
        .top => .{ .left = x - w / 2, .top = y - bubble_height - anchor_gap },
        .right => .{ .left = x + anchor_gap, .top = y - bubble_height / 2 },
        .left => .{ .left = x - w - anchor_gap, .top = y - bubble_height / 2 },
    };
}

pub const Tooltip = struct {
    text: []const u8,
    anchor_x: f32 = 0,
    anchor_y: f32 = 0,
    position_value: Position = .top,
    open_value: bool = true,

    pub fn init(text: []const u8) Tooltip {
        return .{ .text = text };
    }

    pub fn at(self: Tooltip, x: f32, y: f32) Tooltip {
        var copy = self;
        copy.anchor_x = x;
        copy.anchor_y = y;
        return copy;
    }

    pub fn position(self: Tooltip, value: Position) Tooltip {
        var copy = self;
        copy.position_value = value;
        return copy;
    }

    pub fn open(self: Tooltip, value: bool) Tooltip {
        var copy = self;
        copy.open_value = value;
        return copy;
    }

    /// The bubble element; an empty container when closed.
    pub fn render(self: Tooltip) zui.Element {
        if (!self.open_value) return zui.div();
        const origin = bubbleOrigin(self.text, self.position_value, self.anchor_x, self.anchor_y);
        return zui.div().absolute()
            .left(origin.left)
            .top(origin.top)
            .h(bubble_height)
            .px(bubble_padding_x)
            .flex_row().items_center()
            .rounded(6)
            .bg(theme.primary)
            .shadow_lg()
            .child(support.strong(self.text, 12, theme.primary_foreground));
    }
};

const std = @import("std");

test "width estimate grows with text and includes padding" {
    try std.testing.expectApproxEqAbs(bubble_padding_x * 2, estimateWidth(""), 0.001);
    const w = estimateWidth("Save file");
    try std.testing.expect(w > bubble_padding_x * 2);
    try std.testing.expectApproxEqAbs(estimateWidth("Save file"), 9 * glyph_width + bubble_padding_x * 2, 0.001);
}

test "bubble origin places the bubble away from the anchor" {
    const bottom = bubbleOrigin("Hi", .bottom, 100, 200);
    try std.testing.expectApproxEqAbs(200 + anchor_gap, bottom.top, 0.001);

    const top = bubbleOrigin("Hi", .top, 100, 200);
    try std.testing.expectApproxEqAbs(200 - bubble_height - anchor_gap, top.top, 0.001);

    const right = bubbleOrigin("Hi", .right, 100, 200);
    try std.testing.expectApproxEqAbs(100 + anchor_gap, right.left, 0.001);

    const left = bubbleOrigin("Hi", .left, 100, 200);
    try std.testing.expect(left.left < 100 - estimateWidth("Hi"));
}
