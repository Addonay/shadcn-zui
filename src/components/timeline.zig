//! Timeline — Ant/Mantine's vertical step list.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const dot_size: f32 = 10;
pub const line_width: f32 = 2;

pub const State = enum { pending, current, complete, failed };

/// Dot fill color for a state (pure; unit-tested).
pub fn dotColor(state: State) zui.Color {
    return switch (state) {
        .pending => theme.secondary,
        .current => theme.primary,
        .complete => theme.success,
        .failed => theme.destructive,
    };
}

pub const Item = struct {
    title: []const u8 = "",
    description: ?[]const u8 = null,
    time_text: ?[]const u8 = null,
    state_kind: State = .pending,
};

pub const Timeline = struct {
    items: []const Item,
    title_width_px: f32 = 220,

    pub fn init(items: []const Item) Timeline {
        return .{ .items = items };
    }

    pub fn titleWidth(self: Timeline, px: f32) Timeline {
        var copy = self;
        copy.title_width_px = px;
        return copy;
    }

    pub fn render(self: Timeline) zui.Element {
        var list = zui.div().flex_col().gap(0);
        const last = self.items.len;
        for (self.items, 0..) |item, index| {
            var column = zui.div().flex_col().items_center().gap(6)
                .child(support.strong(item.title, 14, theme.foreground));
            if (item.description) |text| {
                column = column.child(support.label(text, 13, theme.muted_foreground));
            }
            if (item.time_text) |text| {
                column = column.child(support.label(text, 12, theme.faint));
            }
            var track = zui.div().flex_col().items_center().w(dot_size).flex_1()
                .child(zui.div().size(dot_size).rounded_full().bg(dotColor(item.state_kind)));
            // Connector line to the next item (none after the last).
            if (index + 1 < last) {
                track = track.child(zui.div().w(line_width).flex_1()
                    .bg(theme.border).rounded_full());
            }
            list = list.child(zui.div().flex_row().gap(12).items_center()
                .child(track)
                .child(zui.div().w(self.title_width_px).flex_col().gap(4).child(column)));
        }
        return list;
    }
};

const std = @import("std");

test "dot colors are distinct per state" {
    try std.testing.expectEqual(theme.primary, dotColor(.current));
    try std.testing.expectEqual(theme.success, dotColor(.complete));
    try std.testing.expectEqual(theme.destructive, dotColor(.failed));
    try std.testing.expectEqual(theme.secondary, dotColor(.pending));
}
