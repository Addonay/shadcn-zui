//! Pagination — shadcn/ui's page row. Controlled.
//!
//! The caller owns the current page and builds one listener per button:
//!
//! ```zig
//! // 1) generate the numbered window (pure):
//! const window = Pagination.pageItems(5, 10); // 1 … 4 5 6 … 10
//! // 2) build Items with listeners (labels formatted into state buffers):
//! var items: [9]Pagination.Item = undefined;
//! items[0] = .{ .kind = .prev, .on_click = cx.listener(State, prevPage) };
//! for (window.slots[0..window.len], 0..) |slot, i| {
//!     if (slot.page) |page| {
//!         const label = std.fmt.bufPrint(&self.page_labels[i], "{d}", .{page}) catch "";
//!         items[i + 1] = .{ .label = label, .current = page == self.page,
//!             .on_click = cx.listenerWith(usize, State, setPage, page) };
//!     } else items[i + 1] = .{ .kind = .ellipsis };
//! }
//! items[window.len + 1] = .{ .kind = .next, .on_click = cx.listener(State, nextPage) };
//! Pagination.init(items[0 .. window.len + 2]).render()
//! ```
//!
//! `pageItems` only produces the numbered window; prev/next are the
//! caller's because they carry the app's own callbacks.

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Kind = enum { page, prev, next, ellipsis };

pub const Item = struct {
    kind: Kind = .page,
    /// Page number text ("1", "2", ...); ignored for prev/next/ellipsis.
    label: []const u8 = "",
    current: bool = false,
    on_click: ?zui.elements.Listener = null,
};

pub const button_size: f32 = 32;
pub const text_size: f32 = 13;

/// A slot in the numbered window: a page number or an ellipsis break.
pub const PageSlot = struct {
    page: ?usize = null,
};

/// The numbered window for `current`/`count`: first, last, and the pages
/// around `current`, with ellipsis breaks where numbers were dropped
/// (shadcn's pattern). Pure; tested.
pub fn pageItems(current: usize, count: usize) struct { slots: [7]PageSlot, len: usize } {
    var slots: [7]PageSlot = undefined;
    var len: usize = 0;

    if (count == 0) return .{ .slots = slots, .len = 0 };
    const current_clamped = @max(1, @min(current, count));

    // Everything fits: no window, no ellipses.
    if (count <= 7) {
        for (1..count + 1) |page| {
            slots[page - 1] = .{ .page = page };
        }
        return .{ .slots = slots, .len = count };
    }

    // Candidate pages in order: first, window, last (deduped, ascending).
    const lo = if (current_clamped > 1) current_clamped - 1 else current_clamped;
    const hi = if (current_clamped < count) current_clamped + 1 else current_clamped;

    var last: ?usize = null;
    for (1..count + 1) |page| {
        const in_window = page == 1 or page == count or (page >= lo and page <= hi);
        if (!in_window) continue;
        // Break where a gap of more than one page was skipped.
        if (last) |previous| {
            if (page > previous + 1) {
                slots[len] = .{};
                len += 1;
            }
        }
        slots[len] = .{ .page = page };
        len += 1;
        last = page;
    }
    return .{ .slots = slots, .len = len };
}

pub const Pagination = struct {
    items: []const Item,

    pub fn init(items: []const Item) Pagination {
        return .{ .items = items };
    }

    pub fn render(self: Pagination) zui.Element {
        var row = zui.div().flex_row().items_center().gap(4);
        for (self.items) |item| {
            row = row.child(renderItem(item));
        }
        return row;
    }
};

fn renderItem(item: Item) zui.Element {
    switch (item.kind) {
        .ellipsis => {
            return zui.div().size(button_size).flex_row().items_center().justify_center()
                .child(support.label("⋯", text_size, theme.muted_foreground));
        },
        .prev, .next => {
            var button = zui.div().size(button_size).flex_row().items_center().justify_center()
                .rounded_lg().hover_bg(theme.accent);
            if (item.on_click) |listener| {
                button = button.cursor_pointer().on_click(listener);
            }
            const glyph: icon_component.Name = if (item.kind == .prev) .chevron_left else .chevron_right;
            return button.child(icon_component.render(glyph, 16, theme.muted_foreground));
        },
        .page => {
            var button = zui.div().size(button_size).flex_row().items_center().justify_center()
                .rounded_lg().border_1();
            button = if (item.current)
                button.border_color(theme.primary).bg(theme.accent)
            else
                button.border_color(theme.input_border).hover_bg(theme.accent);
            if (item.on_click) |listener| {
                button = button.cursor_pointer().on_click(listener);
            }
            return button.child(support.label(
                item.label,
                text_size,
                if (item.current) theme.foreground else theme.muted_foreground,
            ));
        },
    }
}

const std = @import("std");

fn collectPages(comptime N: usize, result: anytype) [N]?usize {
    var pages: [N]?usize = undefined;
    var n: usize = 0;
    for (result.slots[0..result.len]) |slot| {
        pages[n] = slot.page;
        n += 1;
    }
    while (n < N) : (n += 1) pages[n] = null;
    return pages;
}

test "page window in the middle collapses to ellipses" {
    const result = pageItems(5, 10);
    const pages = collectPages(8, result);
    const expected = [8]?usize{ 1, null, 4, 5, 6, null, 10, null };
    try std.testing.expectEqualSlices(?usize, &expected, &pages);
}

test "small count fits without ellipses" {
    const result = pageItems(1, 5);
    const pages = collectPages(8, result);
    const expected = [8]?usize{ 1, 2, 3, 4, 5, null, null, null };
    try std.testing.expectEqualSlices(?usize, &expected, &pages);
}

test "count of 7 renders every page without ellipses" {
    const result = pageItems(7, 7);
    const pages = collectPages(8, result);
    const expected = [8]?usize{ 1, 2, 3, 4, 5, 6, 7, null };
    try std.testing.expectEqualSlices(?usize, &expected, &pages);
}

test "large count at the end collapses the middle" {
    const result = pageItems(19, 20);
    const pages = collectPages(8, result);
    const expected = [8]?usize{ 1, null, 18, 19, 20, null, null, null };
    try std.testing.expectEqualSlices(?usize, &expected, &pages);
}

test "window at the start keeps first and last" {
    const result = pageItems(1, 9);
    const pages = collectPages(8, result);
    const expected = [8]?usize{ 1, 2, null, 9, null, null, null, null };
    try std.testing.expectEqualSlices(?usize, &expected, &pages);
}

test "clamps out-of-range current" {
    const result = pageItems(99, 10);
    var has_current = false;
    for (result.slots[0..result.len]) |slot| {
        if (slot.page == 10) has_current = true;
    }
    try std.testing.expect(has_current);
}
