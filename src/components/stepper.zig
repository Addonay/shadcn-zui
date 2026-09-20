//! Stepper — a horizontal step indicator (gpui-kit's `stepper`).

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const State = enum { incomplete, current, complete };

pub const Item = struct {
    title: []const u8 = "",
    description: []const u8 = "",
    state: State = .incomplete,
    /// Text shown inside the circle ("1", "2", ...) — caller-owned.
    label: []const u8 = "",
};

pub const circle_size: f32 = 28;

pub const CircleStyle = struct {
    background: ?zui.Color,
    border: zui.Color,
    text: zui.Color,
};

/// Circle palette per state (pure; unit-tested).
pub fn circleStyle(state: State) CircleStyle {
    return switch (state) {
        .incomplete => .{ .background = null, .border = theme.border, .text = theme.muted_foreground },
        .current => .{ .background = null, .border = theme.primary, .text = theme.foreground },
        .complete => .{ .background = theme.primary, .border = theme.primary, .text = theme.primary_foreground },
    };
}

pub const Stepper = struct {
    items: []const Item,

    pub fn init(items: []const Item) Stepper {
        return .{ .items = items };
    }

    pub fn render(self: Stepper) zui.Element {
        var row = zui.div().flex_row().items_center().gap(12);
        for (self.items, 0..) |item, index| {
            if (index > 0) {
                row = row.child(zui.div().flex_1().h(1).bg(theme.border));
            }
            row = row.child(stepItem(item));
        }
        return row;
    }
};

fn stepItem(item: Item) zui.Element {
    const circle = circleStyle(item.state);
    var ring = zui.div().size(circle_size).flex_row().items_center().justify_center()
        .rounded_full().border_1().border_color(circle.border);
    if (circle.background) |background| ring = ring.bg(background);

    // Complete steps show a check; others the caller's label.
    const glyph: zui.Element = if (item.state == .complete)
        icon_component.render(semantic.check, 14, theme.primary_foreground)
    else
        support.label(item.label, 13, circle.text);
    ring = ring.child(glyph);

    var text_block = zui.div().flex_col().gap(2)
        .child(support.label(item.title, 13, if (item.state == .incomplete) theme.muted_foreground else theme.foreground));
    if (item.description.len > 0) {
        text_block = text_block.child(support.label(item.description, 12, theme.muted_foreground));
    }

    return zui.div().flex_row().items_center().gap(10)
        .child(ring)
        .child(text_block);
}

const std = @import("std");

test "circle styles per state" {
    const incomplete = circleStyle(.incomplete);
    try std.testing.expect(incomplete.background == null);
    try std.testing.expectEqual(theme.border, incomplete.border);

    const current = circleStyle(.current);
    try std.testing.expectEqual(theme.primary, current.border);

    const complete = circleStyle(.complete);
    try std.testing.expectEqual(theme.primary, complete.background.?);
    try std.testing.expectEqual(theme.primary_foreground, complete.text);
}
