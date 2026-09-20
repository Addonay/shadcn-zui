//! Tree — gpui-kit/Ant/Mantine's hierarchical rows. The app flattens its
//! hierarchy into `Row`s (depth + state + listener); this renders the
//! indent/chevron chrome and tracks state styling.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");

pub const row_height: f32 = 30;
pub const indent_px: f32 = 18;

pub const Row = struct {
    label: []const u8,
    depth: u8 = 0,
    has_children: bool = false,
    open: bool = false,
    selected: bool = false,
    icon_name: ?icon_component.Name = null,
    on_click: ?zui.elements.Listener = null,
};

/// Indent width for a depth (pure; unit-tested).
pub fn indentFor(depth: u8) f32 {
    return @as(f32, @floatFromInt(depth)) * 18;
}

pub const Tree = struct {
    rows: []const Row,
    width_px: f32 = 280,

    pub fn init(rows: []const Row) Tree {
        return .{ .rows = rows };
    }

    pub fn width(self: Tree, px: f32) Tree {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn render(self: Tree) zui.Element {
        var panel = zui.div().flex_col().gap(1).p(4)
            .w(self.width_px).rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border);
        for (self.rows) |row| {
            var slot = zui.div().flex_row().items_center().gap(6).h(row_height).px(8)
                .rounded(6).hover_bg(theme.accent);
            if (row.selected) slot = slot.bg(theme.accent);
            if (row.on_click != null) slot = slot.cursor_pointer();
            if (row.on_click) |listener| slot = slot.on_click(listener);
            const chevron: ?icon_component.Name = if (row.has_children)
                (if (row.open) .chevron_down else .chevron_right)
            else
                null;
            if (indentFor(row.depth) > 0) {
                slot = slot.child(zui.div().w(indentFor(row.depth)).h(1));
            }
            if (chevron) |name| {
                slot = slot.child(icon_component.render(name, 14, theme.muted_foreground));
            } else {
                slot = slot.child(zui.div().w(14));
            }
            if (row.icon_name) |name| {
                slot = slot.child(icon_component.render(name, 15, theme.muted_foreground));
            }
            slot = slot.child(support.label(row.label, 13, theme.body));
            panel = panel.child(slot);
        }
        return panel;
    }
};

const std = @import("std");

test "indent scales with depth" {
    try std.testing.expectEqual(@as(f32, 0), indentFor(0));
    try std.testing.expectEqual(@as(f32, 54), indentFor(3));
}
