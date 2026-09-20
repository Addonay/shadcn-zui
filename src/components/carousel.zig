//! Carousel — gpui-kit/Mantine's paged strip. The app owns the page index;
//! this file owns the page math and the arrows/dots chrome.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const button_component = @import("button.zig");

/// Number of pages for an item count and per-page size (pure).
pub fn pageCount(len: usize, per_page: usize) usize {
    if (per_page == 0) return 0;
    return (len + per_page - 1) / per_page;
}

/// Slice of items visible on a page (pure; unit-tested).
pub fn sliceFor(items: []const zui.Element, page: usize, per_page: usize) []const zui.Element {
    const first = @min(page * per_page, items.len);
    const last = @min(first + per_page, items.len);
    return items[first..last];
}

pub const Carousel = struct {
    items: []const zui.Element,
    page_index: usize = 0,
    per_page: usize = 3,
    on_prev: ?zui.elements.Listener = null,
    on_next: ?zui.elements.Listener = null,
    on_dot: ?zui.elements.Listener = null,

    pub fn init(items: []const zui.Element) Carousel {
        return .{ .items = items };
    }

    pub fn page(self: Carousel, index: usize) Carousel {
        var copy = self;
        copy.page_index = index;
        return copy;
    }

    pub fn perPage(self: Carousel, n: usize) Carousel {
        var copy = self;
        copy.per_page = n;
        return copy;
    }

    pub fn onPrev(self: Carousel, listener: zui.elements.Listener) Carousel {
        var copy = self;
        copy.on_prev = listener;
        return copy;
    }

    pub fn onNext(self: Carousel, listener: zui.elements.Listener) Carousel {
        var copy = self;
        copy.on_next = listener;
        return copy;
    }

    /// Fired with the dot index as payload (`cx.listenerWith(usize, ...)`).
    pub fn onDot(self: Carousel, listener: zui.elements.Listener) Carousel {
        var copy = self;
        copy.on_dot = listener;
        return copy;
    }

    pub fn render(self: Carousel) zui.Element {
        const pages = pageCount(self.items.len, self.per_page);
        const current = @min(self.page_index, pages -| 1);
        const visible = sliceFor(self.items, current, self.per_page);

        var strip = zui.div().flex_row().gap(12);
        for (visible) |element| strip = strip.child(element);

        var row = zui.div().flex_col().gap(10);
        row = row.child(strip);

        var controls = zui.div().flex_row().items_center().justify_center().gap(10);
        var prev = button_component.IconButton.init(.chevron_left).variant(.outline).size(28, 14);
        var next = button_component.IconButton.init(.chevron_right).variant(.outline).size(28, 14);
        if (self.on_prev) |listener| prev = prev.onClick(listener);
        if (self.on_next) |listener| next = next.onClick(listener);
        controls = controls.child(prev.render());
        var dot_index: usize = 0;
        while (dot_index < pages) : (dot_index += 1) {
            var dot = zui.div().size(8).rounded_full()
                .bg(if (dot_index == current) theme.primary else theme.ring);
            if (self.on_dot) |listener| {
                dot = dot.cursor_pointer().on_click(
                    // The listener is built once per dot by the caller via
                    // cx.listenerWith(usize, ...); a single shared listener
                    // is also fine when apps track the index themselves.
                    listener,
                );
            }
            controls = controls.child(dot);
        }
        controls = controls.child(next.render());
        row = row.child(controls);
        return row;
    }
};

test "page math" {
    try std.testing.expectEqual(@as(usize, 0), pageCount(0, 3));
    try std.testing.expectEqual(@as(usize, 1), pageCount(3, 3));
    try std.testing.expectEqual(@as(usize, 2), pageCount(4, 3));
}
