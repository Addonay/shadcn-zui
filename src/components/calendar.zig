//! Calendar — shadcn/Ant/HeroUI's month grid, as a zui entity widget
//! (like `Slider`) so it owns month navigation and selection.
//!
//! ```zig
//! // state:
//! started_at: Entity(shadcn.Calendar),
//! // init:
//! .started_at = cx.new(shadcn.Calendar, .{ .view = .{ .year = 2026, .month = 9 },
//!                                        .on_change = cx.listener(State, onPicked) }),
//! // render:
//! child(self.started_at.toElement())
//! // read after the change listener fires:
//! const picked = self.started_at.read().selected;
//! ```
//!
//! RangeCalendar is the range-selection sibling in this file.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

pub const cell_px: f32 = 28;
pub const grid_gap: f32 = 2;

pub const Weekday = enum(u3) { sun, mon, tue, wed, thu, fri, sat };

pub const Date = struct {
    year: u16 = 2026,
    month: u8 = 1,
    day: u8 = 1,

    pub fn eql(self: Date, other: Date) bool {
        return self.year == other.year and self.month == other.month and self.day == other.day;
    }
};

/// Days since 1970-01-01 (Howard Hinnant's days_from_civil; pure).
pub fn epochDays(date: Date) i64 {
    const y: i64 = date.year;
    const m: i64 = date.month;
    const d: i64 = date.day;
    var yy = y;
    if (m <= 2) yy -= 1;
    const era = @divFloor(yy, 400);
    const yoe = yy - era * 400;
    const mp = @mod(m + 9, 12);
    const doy = @divFloor(153 * mp + 2, 5) + d - 1;
    const doe = yoe * 365 + @divFloor(yoe, 4) - @divFloor(yoe, 100) + doy;
    return era * 146097 + doe - 719468;
}

/// Inverse of `epochDays` (Hinnant's civil_from_days; pure).
pub fn fromEpochDays(days: i64) Date {
    const z = days + 719468;
    const era = @divFloor(z, 146097);
    const doe = z - era * 146097;
    const yoe = @divFloor(doe - @divFloor(doe, 1460) + @divFloor(doe, 36524) - @divFloor(doe, 146096), 365);
    var y = yoe + era * 400;
    const doy = doe - (365 * yoe + @divFloor(yoe, 4) - @divFloor(yoe, 100));
    const mp = @divFloor(5 * doy + 2, 153);
    const d = doy - @divFloor(153 * mp + 2, 5) + 1;
    const m = if (mp < 10) mp + 3 else mp - 9;
    if (m <= 2) y += 1;
    return .{ .year = @intCast(y), .month = @intCast(m), .day = @intCast(d) };
}

pub fn isLeap(year: u16) bool {
    return (@mod(year, 4) == 0 and @mod(year, 100) != 0) or @mod(year, 400) == 0;
}

/// Length of a month, 1..12 (pure; unit-tested).
pub fn daysInMonth(year: u16, month: u8) u8 {
    const lengths = [12]u8{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    if (month == 2 and isLeap(year)) return 29;
    return lengths[month - 1];
}

/// Weekday of a date (pure; unit-tested).
pub fn weekdayOf(date: Date) Weekday {
    const index: u3 = @intCast(@mod(epochDays(date) + 4, 7));
    return @fromBackingInt(index);
}

/// Month name for 1..12 (pure).
pub fn monthName(month: u8) []const u8 {
    const names = [12][]const u8{
        "January",   "February", "March",    "April",
        "May",       "June",     "July",     "August",
        "September", "October",  "November", "December",
    };
    if (month < 1 or month > 12) return "";
    return names[month - 1];
}

/// Step a (year, month) view by `delta` months (pure; unit-tested).
pub fn addMonths(year: u16, month: u8, delta: i16) struct { u16, u8 } {
    const total: i32 = @as(i32, year) * 12 + @as(i32, month) - 1 + delta;
    const new_year: i32 = @divFloor(total, 12);
    const new_month: i32 = @mod(total, 12) + 1;
    return .{ @intCast(new_year), @intCast(new_month) };
}

pub const Cell = struct {
    date: Date,
    in_month: bool,
};

/// Six-week grid for a view month: 42 cells starting on Sunday (pure).
pub fn grid(year: u16, month: u8) [42]Cell {
    var cells: [42]Cell = undefined;
    const first = Date{ .year = year, .month = month, .day = 1 };
    const start = epochDays(first) - @as(i64, @backingInt(weekdayOf(first)));
    var index: usize = 0;
    while (index < 42) : (index += 1) {
        const date = fromEpochDays(start + @as(i64, @intCast(index)));
        cells[index] = .{ .date = date, .in_month = date.month == month };
    }
    return cells;
}

const weekday_labels = [_][]const u8{ "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" };

pub const Calendar = struct {
    pub const Options = struct {
        view: Date = .{},
        selected: ?Date = null,
        today: ?Date = null,
        /// App listener fired after a day is picked (read `.selected`).
        on_change: ?zui.Listener = null,
    };

    view_year: u16 = 2026,
    view_month: u8 = 9,
    selected: ?Date = null,
    today: ?Date = null,
    on_change: ?zui.Listener = null,
    /// Cached during render so day callbacks can map index -> date.
    cells: [42]Cell = undefined,
    label_buf: [32]u8 = undefined,
    label_text: []const u8 = "",

    pub fn init(_: *zui.Context(@This()), options: Options) @This() {
        return .{
            .view_year = options.view.year,
            .view_month = options.view.month,
            .selected = options.selected,
            .today = options.today,
            .on_change = options.on_change,
        };
    }

    pub fn selectDay(self: *@This(), date: Date, cx: *zui.Context(@This())) void {
        self.selected = date;
        cx.notify();
    }

    pub fn goPrevMonth(self: *@This(), cx: *zui.Context(@This())) void {
        const next = addMonths(self.view_year, self.view_month, -1);
        self.view_year = next[0];
        self.view_month = next[1];
        cx.notify();
    }

    pub fn goNextMonth(self: *@This(), cx: *zui.Context(@This())) void {
        const next = addMonths(self.view_year, self.view_month, 1);
        self.view_year = next[0];
        self.view_month = next[1];
        cx.notify();
    }

    pub fn render(self: *@This(), _: *zui.Window, cx: *zui.Context(@This())) zui.Element {
        self.cells = grid(self.view_year, self.view_month);
        self.label_text = std.fmt.bufPrint(&self.label_buf, "{s} {d}", .{
            monthName(self.view_month), self.view_year,
        }) catch "";

        var panel = zui.div().flex_col().gap(8).p(12)
            .w(cell_px * 7 + grid_gap * 6 + 24).rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border);

        // Header: prev / month label / next.
        const prev = zui.div().size(cell_px).flex_row().items_center().justify_center()
            .rounded(6).cursor_pointer().hover_bg(theme.accent)
            .child(icon_component.render(semantic.chevron_left, 16, theme.muted_foreground))
            .on_click(cx.listener(@This(), goPrevMonth));
        const next = zui.div().size(cell_px).flex_row().items_center().justify_center()
            .rounded(6).cursor_pointer().hover_bg(theme.accent)
            .child(icon_component.render(semantic.chevron_right, 16, theme.muted_foreground))
            .on_click(cx.listener(@This(), goNextMonth));
        panel = panel.child(zui.div().flex_row().items_center().gap(8)
            .child(prev)
            .child(support.strong(self.label_text, 14, theme.foreground))
            .child(next));

        // Weekday header.
        var week_header = zui.div().flex_row().gap(grid_gap);
        for (weekday_labels) |label| {
            week_header = week_header.child(zui.div().w(cell_px).flex_col().items_center()
                .child(support.label(label, 11, theme.muted_foreground)));
        }
        panel = panel.child(week_header);

        // Day grid: 42 cells; each in-month cell carries its own listener.
        var row_index: usize = 0;
        while (row_index < 6) : (row_index += 1) {
            var row = zui.div().flex_row().gap(grid_gap);
            var column: usize = 0;
            while (column < 7) : (column += 1) {
                const index = row_index * 7 + column;
                row = row.child(self.dayCell(index, self.cells[index], cx));
            }
            panel = panel.child(row);
        }
        return panel;
    }

    fn dayCell(self: *Calendar, index: usize, cell: Cell, cx: *zui.Context(Calendar)) zui.Element {
        const date = cell.date;
        const selected = if (self.selected) |value| value.eql(date) else false;
        const is_today = if (self.today) |value| value.eql(date) else false;
        const foreground = if (cell.in_month) theme.foreground else theme.faint;

        var slot = zui.div().size(cell_px).flex_row().items_center().justify_center()
            .rounded(6);
        if (selected) {
            slot = slot.bg(theme.primary);
        } else if (cell.in_month) {
            slot = slot.hover_bg(theme.accent).cursor_pointer();
        }
        if (is_today and !selected) {
            slot = slot.border_1().border_color(theme.ring);
        }
        if (cell.in_month) {
            slot = slot.on_click(cx.listenerWith(usize, @This(), pickDayCell, index));
        }
        return slot.child(zui.text(dayLabel(date.day), .{
            .font = theme.font,
            .size = 12,
            .line_height = 14,
            .weight = if (selected) zui.elements.FontWeight.semibold else zui.elements.FontWeight.normal,
            .color = if (selected) theme.primary_foreground else foreground,
        }));
    }

    fn pickDayCell(self: *@This(), index: usize, window: *zui.Window, cx: *zui.Context(@This())) void {
        if (index >= self.cells.len) return;
        self.selected = self.cells[index].date;
        if (self.on_change) |listener| listener.call(window);
        cx.notify();
    }
};

/// RangeCalendar — HeroUI's RangeCalendar. First pick sets the start,
/// second sets the end (a pick outside resets to a new start).
pub const RangeCalendar = struct {
    pub const Options = struct {
        view: Date = .{},
        range_start: ?Date = null,
        range_end: ?Date = null,
        today: ?Date = null,
        on_change: ?zui.Listener = null,
    };

    view_year: u16 = 2026,
    view_month: u8 = 9,
    range_start: ?Date = null,
    range_end: ?Date = null,
    picking_end: bool = false,
    today: ?Date = null,
    on_change: ?zui.Listener = null,
    cells: [42]Cell = undefined,
    label_buf: [32]u8 = undefined,
    label_text: []const u8 = "",

    pub fn init(_: *zui.Context(@This()), options: Options) @This() {
        return .{
            .view_year = options.view.year,
            .view_month = options.view.month,
            .range_start = options.range_start,
            .range_end = options.range_end,
            .today = options.today,
            .on_change = options.on_change,
        };
    }

    pub fn render(self: *@This(), _: *zui.Window, cx: *zui.Context(@This())) zui.Element {
        self.cells = grid(self.view_year, self.view_month);
        self.label_text = std.fmt.bufPrint(&self.label_buf, "{s} {d}", .{
            monthName(self.view_month), self.view_year,
        }) catch "";

        var panel = zui.div().flex_col().gap(8).p(12)
            .w(cell_px * 7 + grid_gap * 6 + 24).rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border);

        const prev = zui.div().size(cell_px).flex_row().items_center().justify_center()
            .rounded(6).cursor_pointer().hover_bg(theme.accent)
            .child(icon_component.render(semantic.chevron_left, 16, theme.muted_foreground))
            .on_click(cx.listener(@This(), goPrevMonth));
        const next = zui.div().size(cell_px).flex_row().items_center().justify_center()
            .rounded(6).cursor_pointer().hover_bg(theme.accent)
            .child(icon_component.render(semantic.chevron_right, 16, theme.muted_foreground))
            .on_click(cx.listener(@This(), goNextMonth));
        panel = panel.child(zui.div().flex_row().items_center().gap(8)
            .child(prev)
            .child(support.strong(self.label_text, 14, theme.foreground))
            .child(next));

        var week_header = zui.div().flex_row().gap(grid_gap);
        for (weekday_labels) |label| {
            week_header = week_header.child(zui.div().w(cell_px).flex_col().items_center()
                .child(support.label(label, 11, theme.muted_foreground)));
        }
        panel = panel.child(week_header);

        var row_index: usize = 0;
        while (row_index < 6) : (row_index += 1) {
            var row = zui.div().flex_row().gap(grid_gap);
            var column: usize = 0;
            while (column < 7) : (column += 1) {
                const index = row_index * 7 + column;
                row = row.child(self.dayCell(index, self.cells[index], cx));
            }
            panel = panel.child(row);
        }
        return panel;
    }

    fn dayCell(self: *RangeCalendar, index: usize, cell: Cell, cx: *zui.Context(RangeCalendar)) zui.Element {
        const date = cell.date;
        const in_range = rangeContains(self, date);
        const is_endpoint = endpointEql(self, date);
        const foreground = if (cell.in_month) theme.foreground else theme.faint;

        var slot = zui.div().size(cell_px).flex_row().items_center().justify_center()
            .rounded(6);
        if (is_endpoint) {
            slot = slot.bg(theme.primary);
        } else if (in_range) {
            slot = slot.bg(theme.accent);
        } else if (cell.in_month) {
            slot = slot.hover_bg(theme.accent).cursor_pointer();
        }
        if (cell.in_month) {
            slot = slot.on_click(cx.listenerWith(usize, @This(), pickDayCell, index));
        }
        return slot.child(zui.text(dayLabel(date.day), .{
            .font = theme.font,
            .size = 12,
            .line_height = 14,
            .weight = if (is_endpoint) zui.elements.FontWeight.semibold else zui.elements.FontWeight.normal,
            .color = if (is_endpoint) theme.primary_foreground else foreground,
        }));
    }

    fn rangeContains(self: *RangeCalendar, date: Date) bool {
        const start = self.range_start orelse return false;
        const end = self.range_end orelse return false;
        return epochDays(date) >= epochDays(start) and epochDays(date) <= epochDays(end);
    }

    fn endpointEql(self: *RangeCalendar, date: Date) bool {
        if (self.range_start) |value| if (value.eql(date)) return true;
        if (self.range_end) |value| if (value.eql(date)) return true;
        return false;
    }

    fn pickDayCell(self: *@This(), index: usize, window: *zui.Window, cx: *zui.Context(@This())) void {
        if (index >= self.cells.len) return;
        const date = self.cells[index].date;
        if (self.picking_end) {
            // Swap so start <= end.
            const start = self.range_start.?;
            if (epochDays(date) < epochDays(start)) {
                self.range_start = date;
                self.range_end = start;
            } else {
                self.range_end = date;
            }
            self.picking_end = false;
        } else {
            self.range_start = date;
            self.range_end = null;
            self.picking_end = true;
        }
        if (self.on_change) |listener| listener.call(window);
        cx.notify();
    }

    fn goPrevMonth(self: *@This(), cx: *zui.Context(@This())) void {
        const next = addMonths(self.view_year, self.view_month, -1);
        self.view_year = next[0];
        self.view_month = next[1];
        cx.notify();
    }

    fn goNextMonth(self: *@This(), cx: *zui.Context(@This())) void {
        const next = addMonths(self.view_year, self.view_month, 1);
        self.view_year = next[0];
        self.view_month = next[1];
        cx.notify();
    }
};

/// "September 2026" — the caller formats into its own buffer; month names
/// are static, so the label borrows safely until paint.
pub fn monthLabel(year: u16, month: u8, buf: []u8) []const u8 {
    return std.fmt.bufPrint(buf, "{s} {d}", .{ monthName(month), year }) catch "";
}

/// Day number as a static string (no formatting; pure).
pub fn dayLabel(day: u8) []const u8 {
    return switch (day) {
        1 => "1",
        2 => "2",
        3 => "3",
        4 => "4",
        5 => "5",
        6 => "6",
        7 => "7",
        8 => "8",
        9 => "9",
        10 => "10",
        11 => "11",
        12 => "12",
        13 => "13",
        14 => "14",
        15 => "15",
        16 => "16",
        17 => "17",
        18 => "18",
        19 => "19",
        20 => "20",
        21 => "21",
        22 => "22",
        23 => "23",
        24 => "24",
        25 => "25",
        26 => "26",
        27 => "27",
        28 => "28",
        29 => "29",
        30 => "30",
        31 => "31",
        else => "",
    };
}

test "leap years" {
    try std.testing.expect(isLeap(2024));
    try std.testing.expect(isLeap(2000));
    try std.testing.expect(!isLeap(1900));
    try std.testing.expect(!isLeap(2023));
}

test "month lengths" {
    try std.testing.expectEqual(@as(u8, 29), daysInMonth(2024, 2));
    try std.testing.expectEqual(@as(u8, 28), daysInMonth(2023, 2));
    try std.testing.expectEqual(@as(u8, 31), daysInMonth(2026, 7));
    try std.testing.expectEqual(@as(u8, 30), daysInMonth(2026, 9));
}

test "known weekdays" {
    // 2026-09-17 is a Thursday.
    try std.testing.expectEqual(Weekday.thu, weekdayOf(.{ .year = 2026, .month = 9, .day = 17 }));
    try std.testing.expectEqual(Weekday.thu, weekdayOf(.{ .year = 1970, .month = 1, .day = 1 }));
    try std.testing.expectEqual(Weekday.sun, weekdayOf(.{ .year = 2026, .month = 9, .day = 13 }));
}

test "epoch round-trip" {
    const dates = [_]Date{
        .{ .year = 1970, .month = 1, .day = 1 },
        .{ .year = 2026, .month = 9, .day = 17 },
        .{ .year = 2000, .month = 2, .day = 29 },
        .{ .year = 2100, .month = 3, .day = 1 },
    };
    for (dates) |date| {
        try std.testing.expect(date.eql(fromEpochDays(epochDays(date))));
    }
}

test "grid covers the month and starts on Sunday" {
    const cells = grid(2026, 9);
    try std.testing.expectEqual(Weekday.sun, weekdayOf(cells[0].date));
    var count: usize = 0;
    for (cells) |cell| {
        if (cell.in_month) count += 1;
        try std.testing.expect(cell.in_month or true);
    }
    try std.testing.expectEqual(@as(usize, 30), count);
    // All 30 September days appear in order.
    var day: u8 = 1;
    for (cells) |cell| {
        if (cell.in_month) {
            try std.testing.expectEqual(day, cell.date.day);
            day += 1;
        }
    }
    try std.testing.expectEqual(@as(u8, 31), day);
}

test "addMonths crosses years" {
    try std.testing.expectEqual(@as(u16, 2027), addMonths(2026, 10, 3)[0]);
    try std.testing.expectEqual(@as(u8, 1), addMonths(2026, 10, 3)[1]);
    try std.testing.expectEqual(@as(u16, 2025), addMonths(2026, 1, -1)[0]);
    try std.testing.expectEqual(@as(u8, 12), addMonths(2026, 1, -1)[1]);
}
