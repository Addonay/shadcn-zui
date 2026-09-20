//! DataTable — a table whose headers sort (shadcn data-table flavor).
//!
//! Sorting itself lives in the app (it owns the row order); the component
//! tracks which column is sorted and which direction, and calls back when a
//! header is clicked:
//!
//! ```zig
//! const columns = [_]DataTable.Column{
//!     .{ .title = "Header", .grow = true },
//!     .{ .title = "Amount", .width = 120,
//!        .sort_state = if (self.sort_col == 1) self.sort_order else .none,
//!        .on_sort = cx.listenerWith(usize, State, toggleSort, 1) },
//! };
//! // rows: same cell/row model as `table.Table`
//! DataTable.init(&columns).rows(&rows).render()
//! ```

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;
const support = @import("../support.zig");
const table_component = @import("table.zig");
const theme = @import("../theme.zig");

pub const SortState = enum { none, asc, desc };

pub const Column = struct {
    title: []const u8 = "",
    width: ?f32 = null,
    grow: bool = false,
    sort_state: SortState = .none,
    on_sort: ?zui.Listener = null,
};

pub const Row = struct {
    cells: []const zui.Element,
    on_click: ?zui.Listener = null,
};

/// Sort arrow + affordance for a column header (pure; unit-tested).
pub fn headerStyle(column: Column) struct { arrow: ?icon_component.Name, foreground: zui.Color, clickable: bool } {
    return switch (column.sort_state) {
        .none => .{ .arrow = null, .foreground = theme.foreground, .clickable = column.on_sort != null },
        .asc => .{ .arrow = semantic.arrow_up, .foreground = theme.foreground, .clickable = true },
        .desc => .{ .arrow = semantic.arrow_down, .foreground = theme.foreground, .clickable = true },
    };
}

pub const DataTable = struct {
    columns: []const Column,
    rows_data: []const table_component.Row = &.{},

    pub fn init(columns: []const Column) DataTable {
        return .{ .columns = columns };
    }

    pub fn rows(self: DataTable, value: []const table_component.Row) DataTable {
        var copy = self;
        copy.rows_data = value;
        return copy;
    }

    pub fn render(self: DataTable) zui.Element {
        var outer = zui.div().flex_col().rounded_lg().border_1().border_color(theme.border);

        // Header: clickable, sorted columns show an arrow.
        var header = zui.div().flex_row().items_center().h(table_component.header_height)
            .px(table_component.padding_x).gap(table_component.gap)
            .bg(theme.secondary);
        for (self.columns) |column| {
            const style = headerStyle(column);
            var cell = zui.div().flex_col().justify_center();
            cell = if (column.grow) cell.flex_1() else cell.w(column.width orelse table_component.default_column_width);
            var label_row = zui.div().flex_row().items_center().gap(4);
            if (style.clickable) {
                label_row = label_row.cursor_pointer().hover_bg(theme.accent).rounded(4).px(4);
                if (column.on_sort) |listener| label_row = label_row.on_click(listener);
            }
            label_row = label_row.child(support.strong(column.title, 14, style.foreground));
            if (style.arrow) |arrow| {
                label_row = label_row.child(icon_component.render(arrow, 14, theme.muted_foreground));
            }
            header = header.child(cell.child(label_row));
        }
        outer = outer.child(header);

        // Body rows reuse the plain table's row renderer (same look).
        for (self.rows_data) |row| {
            outer = outer.child(table_component.renderRow(row, false, self.columns));
        }
        return outer;
    }
};

const std = @import("std");

test "header style follows sort state" {
    const plain = headerStyle(.{ .title = "Header" });
    try std.testing.expect(plain.arrow == null);
    try std.testing.expect(!plain.clickable);

    const sortable = headerStyle(.{ .title = "Amount", .on_sort = undefined, .sort_state = .none });
    try std.testing.expect(sortable.clickable);

    const ascending = headerStyle(.{ .sort_state = .asc });
    try std.testing.expectEqual(semantic.arrow_up, ascending.arrow.?);
    const descending = headerStyle(.{ .sort_state = .desc });
    try std.testing.expectEqual(semantic.arrow_down, descending.arrow.?);
}

test "metrics follow the plain table" {
    try std.testing.expectEqual(@as(f32, 40), table_component.header_height);
    try std.testing.expectEqual(@as(f32, 52), table_component.row_height);
}
