//! List — gpui-kit's List / HeroUI's ListBox: a selectable item panel.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");

pub const default_width: f32 = 256;
pub const row_height: f32 = 36;

pub const Item = struct {
    label: []const u8 = "",
    description: ?[]const u8 = null,
    icon_name: ?icon_component.Name = null,
    selected: bool = false,
    disabled: bool = false,
    on_click: ?zui.Listener = null,
};

/// Row chrome for a state (pure; unit-tested).
pub fn rowStyle(item: Item) struct { bg: ?zui.Color, foreground: zui.Color } {
    if (item.disabled) return .{ .bg = null, .foreground = theme.faint };
    if (item.selected) return .{ .bg = theme.accent, .foreground = theme.foreground };
    return .{ .bg = null, .foreground = theme.body };
}

pub const List = struct {
    items: []const Item,
    width_px: f32 = default_width,
    /// Optional section header label above the rows.
    heading_text: ?[]const u8 = null,

    pub fn init(items: []const Item) List {
        return .{ .items = items };
    }

    pub fn width(self: List, px: f32) List {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn heading(self: List, text: []const u8) List {
        var copy = self;
        copy.heading_text = text;
        return copy;
    }

    pub fn render(self: List) zui.Element {
        var panel = zui.div().flex_col().gap(2).p(4)
            .w(self.width_px).rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border);
        if (self.heading_text) |text| {
            panel = panel.child(support.label(text, 12, theme.muted_foreground));
        }
        for (self.items) |item| {
            const style = rowStyle(item);
            var row = zui.div().flex_row().items_center().gap(10).h(row_height).px(10)
                .rounded(8);
            if (style.bg) |color| row = row.bg(color);
            if (!item.disabled) row = row.hover_bg(theme.accent);
            if (item.on_click != null and !item.disabled) {
                row = row.cursor_pointer().on_click(item.on_click.?);
            }
            if (item.icon_name) |name| {
                row = row.child(icon_component.render(name, 16, theme.muted_foreground));
            }
            var col = zui.div().flex_col().gap(1)
                .child(support.label(item.label, 14, style.foreground));
            if (item.description) |text| {
                col = col.child(support.label(text, 12, theme.muted_foreground));
            }
            row = row.child(col);
            panel = panel.child(row);
        }
        return panel;
    }
};

const std = @import("std");

test "row styles" {
    const disabled = rowStyle(.{ .disabled = true });
    try std.testing.expectEqual(theme.faint, disabled.foreground);
    const selected = rowStyle(.{ .selected = true });
    try std.testing.expectEqual(theme.accent, selected.bg.?);
}
