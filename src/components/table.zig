//! Table — a generic, allocation-free data table in the dashboard's style.
//!
//! The caller owns the data and builds one `zui.Element` per cell during the
//! render pass (elements are frame-local, so never cache them across frames).
//! The table just lays the cells out with the dashboard's metrics: a 40px
//! header on `theme.secondary`, 52px body rows with a bottom border, 16px
//! horizontal padding, 20px gaps, and an optional 16px selection column.
//!
//! ```zig
//! // Built inside `render`, once per frame.
//! const columns = [_]Table.Column{
//!     .{ .title = "Header", .grow = true },
//!     .{ .title = "Section Type", .width = 210 },
//!     .{ .title = "Status", .width = 180 },
//! };
//! const rows = [_]Table.Row{
//!     .{
//!         .cells = &.{
//!             support.strong("Invoice #1042", 14, theme.foreground),
//!             support.label("Billing", 14, theme.foreground),
//!             support.label("Done", 14, theme.foreground),
//!         },
//!         .selected = true,
//!         .selection = cx.listenerWith(usize, State, toggleRow, 0),
//!         .on_click = cx.listenerWith(usize, State, openRow, 0),
//!     },
//!     .{
//!         .cells = &.{
//!             support.strong("Invoice #1043", 14, theme.foreground),
//!             support.label("Payroll", 14, theme.foreground),
//!             support.label("In Process", 14, theme.foreground),
//!         },
//!     },
//! };
//!
//! Table.init(&columns)
//!     .rows(&rows)
//!     .selectable(true)
//!     .allSelected(false)
//!     .onSelectAll(cx.listener(State, toggleAll))
//!     .render()
//! ```
//!
//! `Row.cells` holds one element per column, in column order. Rows with fewer
//! cells get an empty placeholder; rows with extra cells get a default-width
//! wrapper so nothing is dropped (prefer keeping `cells.len == columns.len`).

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const checkbox = @import("checkbox.zig");

/// Header row height, from the dashboard reference.
pub const header_height: f32 = 40;
/// Body row height, from the dashboard reference.
pub const row_height: f32 = 52;
/// Horizontal padding shared by the header and every body row.
pub const padding_x: f32 = 16;
/// Gap between the selection column and the data columns.
pub const gap: f32 = 20;
/// The leading (and reserved trailing) selection slot width.
pub const checkbox_size: f32 = 16;
/// Width used by a fixed column that does not set `width`.
pub const default_column_width: f32 = 160;
/// Header title size.
pub const header_text_size: f32 = 14;

/// One table column. `grow` makes the column absorb the remaining row width
/// (`.flex_1()`); otherwise the wrapper is fixed at `width` (or 160px).
pub const Column = struct {
    title: []const u8 = "",
    width: ?f32 = null,
    grow: bool = false,
};

/// One body row. `cells` must line up with `Table.columns` by index.
pub const Row = struct {
    cells: []const zui.Element,
    selected: bool = false,
    /// Per-row checkbox listener; the checkbox still paints when absent.
    selection: ?zui.elements.Listener = null,
    /// Whole-row click; also enables the pointer cursor and hover tint.
    on_click: ?zui.elements.Listener = null,
};

/// Resolved width rule for a column wrapper.
pub const ColumnWidth = struct {
    grow: bool,
    width: f32,
};

/// Pure resolution of a column's width rule (used by `render`, unit-tested).
pub fn columnWidth(column: anytype) ColumnWidth {
    return .{ .grow = column.grow, .width = column.width orelse default_column_width };
}

/// Background for a body row; selected rows use the accent tint.
pub fn rowBackground(selected: bool) ?zui.Color {
    return if (selected) theme.accent else null;
}

pub const Table = struct {
    columns: []const Column,
    rows_data: []const Row = &.{},
    selectable_value: bool = false,
    all_selected: bool = false,
    select_all: ?zui.elements.Listener = null,

    pub fn init(columns: []const Column) Table {
        return .{ .columns = columns };
    }

    pub fn rows(self: Table, value: []const Row) Table {
        var copy = self;
        copy.rows_data = value;
        return copy;
    }

    pub fn selectable(self: Table, value: bool) Table {
        var copy = self;
        copy.selectable_value = value;
        return copy;
    }

    pub fn allSelected(self: Table, value: bool) Table {
        var copy = self;
        copy.all_selected = value;
        return copy;
    }

    pub fn onSelectAll(self: Table, listener: zui.elements.Listener) Table {
        var copy = self;
        copy.select_all = listener;
        return copy;
    }

    pub fn render(self: Table) zui.Element {
        var table = zui.div().flex_col().rounded_lg()
            .border_1().border_color(theme.border)
            .child(header(self));
        for (self.rows_data) |row_data| {
            table = table.child(bodyRow(self, row_data));
        }
        return table;
    }

    fn header(self: Table) zui.Element {
        var header_row = zui.div().flex_row().items_center()
            .h(header_height).px(padding_x).gap(gap)
            .bg(theme.secondary);
        if (self.selectable_value) {
            header_row = header_row.child(selectionCell(self.all_selected, self.select_all));
        }
        for (self.columns) |column| {
            header_row = header_row.child(columnCell(column, support.strong(column.title, header_text_size, theme.foreground)));
        }
        if (self.selectable_value) header_row = header_row.child(trailingSlot());
        return header_row;
    }

    fn bodyRow(self: Table, row_data: Row) zui.Element {
        return renderRow(row_data, self.selectable_value, self.columns);
    }
};

/// One body row. Shared with `data_table`, which renders its own sortable
/// header and reuses the row look. Render the wider of the two slices so a
/// miscounted row never drops a cell; missing cells become empty wrappers
/// and keep the alignment.
pub fn renderRow(row_data: Row, selectable: bool, columns: anytype) zui.Element {
    var row = zui.div().flex_row().items_center()
        .h(row_height).px(padding_x).gap(gap)
        .border_b_1().border_color(theme.border);
    if (row_data.on_click) |listener| {
        row = row.cursor_pointer().hover_bg(theme.accent).on_click(listener);
    }
    if (rowBackground(row_data.selected)) |color| row = row.bg(color);
    if (selectable) {
        row = row.child(selectionCell(row_data.selected, row_data.selection));
    }
    const cell_count = @max(columns.len, row_data.cells.len);
    var index: usize = 0;
    while (index < cell_count) : (index += 1) {
        const cell = if (index < row_data.cells.len) row_data.cells[index] else zui.div();
        const column = if (index < columns.len) columns[index] else @as(@TypeOf(columns[0]), .{});
        row = row.child(columnCell(column, cell));
    }
    if (selectable) row = row.child(trailingSlot());
    return row;
}

/// The 16px selection slot: checkbox plus the dashboard's reserved right edge.
fn selectionCell(checked: bool, listener: ?zui.elements.Listener) zui.Element {
    var box = checkbox.Checkbox.init().checked(checked);
    if (listener) |value| box = box.onToggle(value);
    return zui.div().w(checkbox_size).child(box.render());
}

/// The matching trailing slot in header and body rows, so grown columns line
/// up (the dashboard reserves the same 16px for its row actions).
fn trailingSlot() zui.Element {
    return zui.div().w(checkbox_size);
}

pub fn columnCell(column: anytype, cell: zui.Element) zui.Element {
    const width = columnWidth(column);
    var wrapper = zui.div();
    if (width.grow) {
        wrapper = wrapper.flex_1();
    } else {
        wrapper = wrapper.w(width.width);
    }
    return wrapper.child(cell);
}

const std = @import("std");

test "columnWidth defaults to a fixed 160px column" {
    const width = columnWidth(Column{ .title = "Header" });
    try std.testing.expect(!width.grow);
    try std.testing.expectEqual(default_column_width, width.width);
}

test "columnWidth honours an explicit width" {
    const width = columnWidth(Column{ .title = "Section Type", .width = 210 });
    try std.testing.expect(!width.grow);
    try std.testing.expectEqual(@as(f32, 210), width.width);
}

test "columnWidth reports grow columns" {
    const width = columnWidth(Column{ .title = "Header", .grow = true });
    try std.testing.expect(width.grow);
    try std.testing.expectEqual(default_column_width, width.width);
}

test "rowBackground tints only selected rows" {
    try std.testing.expect(rowBackground(false) == null);
    try std.testing.expectEqual(theme.accent, rowBackground(true).?);
}

test "metrics mirror the dashboard rows" {
    try std.testing.expectEqual(@as(f32, 40), header_height);
    try std.testing.expectEqual(@as(f32, 52), row_height);
    try std.testing.expectEqual(@as(f32, 16), padding_x);
    try std.testing.expectEqual(@as(f32, 20), gap);
    try std.testing.expectEqual(@as(f32, 16), checkbox_size);
}

test "builder methods return updated copies" {
    const columns = [_]Column{.{ .title = "Header", .grow = true }};
    const base = Table.init(&columns);
    try std.testing.expect(!base.selectable_value);
    try std.testing.expect(!base.all_selected);
    try std.testing.expect(base.select_all == null);
    try std.testing.expectEqual(@as(usize, 0), base.rows_data.len);

    const configured = base.selectable(true).allSelected(true);
    try std.testing.expect(configured.selectable_value);
    try std.testing.expect(configured.all_selected);
    try std.testing.expectEqual(@as(usize, 1), configured.columns.len);
    // Value semantics: the original stays untouched.
    try std.testing.expect(!base.selectable_value);
}
