//! RadioGroup — shadcn/ui's single-choice list. Controlled.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const indicator_size: f32 = 16;
pub const dot_size: f32 = 8;
pub const row_gap: f32 = 10;
pub const list_gap: f32 = 12;

pub const Item = struct {
    label: []const u8 = "",
    description: []const u8 = "",
    selected: bool = false,
    disabled: bool = false,
    on_click: ?zui.elements.Listener = null,
};

/// Indicator palette (pure; unit-tested).
pub fn indicatorStyle(selected: bool) struct { border: zui.Color, dot: ?zui.Color } {
    return .{
        .border = if (selected) theme.primary else theme.border_strong,
        .dot = if (selected) theme.primary else null,
    };
}

pub const RadioGroup = struct {
    items: []const Item,
    gap_px: f32 = list_gap,

    pub fn init(items: []const Item) RadioGroup {
        return .{ .items = items };
    }

    pub fn gap(self: RadioGroup, px: f32) RadioGroup {
        var copy = self;
        copy.gap_px = px;
        return copy;
    }

    pub fn render(self: RadioGroup) zui.Element {
        var list = zui.div().flex_col().gap(self.gap_px);
        for (self.items) |item| {
            list = list.child(renderRow(item));
        }
        return list;
    }
};

fn renderRow(item: Item) zui.Element {
    const style = indicatorStyle(item.selected);
    var indicator = zui.div().size(indicator_size).flex_row().items_center().justify_center()
        .rounded_full().border_1().border_color(style.border);
    if (style.dot) |dot| {
        indicator = indicator.child(zui.div().size(dot_size).rounded_full().bg(dot));
    }

    var text_block = zui.div().flex_col().gap(2)
        .child(support.label(item.label, 14, theme.foreground));
    if (item.description.len > 0) {
        text_block = text_block.child(support.label(item.description, 13, theme.muted_foreground));
    }

    var row = zui.div().flex_row().items_center().gap(row_gap);
    if (!item.disabled) {
        row = row.cursor_pointer();
        if (item.on_click) |listener| row = row.on_click(listener);
    } else {
        row = row.opacity(0.5);
    }
    return row.child(indicator).child(text_block);
}

const std = @import("std");

test "indicator style follows selection" {
    const unselected = indicatorStyle(false);
    try std.testing.expectEqual(theme.border_strong, unselected.border);
    try std.testing.expect(unselected.dot == null);

    const selected = indicatorStyle(true);
    try std.testing.expectEqual(theme.primary, selected.border);
    try std.testing.expectEqual(theme.primary, selected.dot.?);
}

test "metrics" {
    try std.testing.expectEqual(@as(f32, 16), indicator_size);
    try std.testing.expectEqual(@as(f32, 8), dot_size);
}
