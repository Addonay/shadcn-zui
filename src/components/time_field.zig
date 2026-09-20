//! TimeField — HeroUI's hour/minute stepper field.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");

/// Wrapped add for hour (0..23) or minute (0..59) values (pure; unit-tested).
pub fn wrapAdd(value: u32, delta: i32, modulus: u32) u32 {
    const base: i32 = @intCast(value);
    const limit: i32 = @intCast(modulus);
    return @intCast(@mod(base + delta, limit));
}

pub const TimeField = struct {
    hour_text: []const u8 = "09",
    minute_text: []const u8 = "41",
    on_hour_up: ?zui.elements.Listener = null,
    on_hour_down: ?zui.elements.Listener = null,
    on_minute_up: ?zui.elements.Listener = null,
    on_minute_down: ?zui.elements.Listener = null,

    pub fn init() TimeField {
        return .{};
    }

    pub fn hour(self: TimeField, text: []const u8) TimeField {
        var copy = self;
        copy.hour_text = text;
        return copy;
    }

    pub fn minute(self: TimeField, text: []const u8) TimeField {
        var copy = self;
        copy.minute_text = text;
        return copy;
    }

    pub fn onHourUp(self: TimeField, listener: zui.elements.Listener) TimeField {
        var copy = self;
        copy.on_hour_up = listener;
        return copy;
    }

    pub fn onHourDown(self: TimeField, listener: zui.elements.Listener) TimeField {
        var copy = self;
        copy.on_hour_down = listener;
        return copy;
    }

    pub fn onMinuteUp(self: TimeField, listener: zui.elements.Listener) TimeField {
        var copy = self;
        copy.on_minute_up = listener;
        return copy;
    }

    pub fn onMinuteDown(self: TimeField, listener: zui.elements.Listener) TimeField {
        var copy = self;
        copy.on_minute_down = listener;
        return copy;
    }

    fn column(label_text: []const u8, value_text: []const u8, up: ?zui.elements.Listener, down: ?zui.elements.Listener) zui.Element {
        var col = zui.div().flex_col().items_center().gap(2);
        for ([_]struct { icon_component.Name, ?zui.elements.Listener }{
            .{ .chevron_up, up },
            .{ .chevron_down, down },
        }) |pair| {
            var button = zui.div().size(26).flex_row().items_center().justify_center()
                .rounded(6).hover_bg(theme.accent)
                .child(icon_component.render(pair[0], 14, theme.muted_foreground));
            if (pair[1]) |listener| button = button.cursor_pointer().on_click(listener);
            col = col.child(button);
        }
        col = col.child(zui.div().h(28).px(8).rounded(6).bg(theme.secondary)
            .flex_row().items_center().justify_center()
            .child(support.strong(value_text, 15, theme.foreground)));
        col = col.child(support.label(label_text, 10, theme.muted_foreground));
        return col;
    }

    pub fn render(self: TimeField) zui.Element {
        return zui.div().flex_row().items_center().gap(10)
            .p(10).rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border)
            .child(column("Hour", self.hour_text, self.on_hour_up, self.on_hour_down))
            .child(support.strong(":", 16, theme.muted_foreground))
            .child(column("Min", self.minute_text, self.on_minute_up, self.on_minute_down));
    }
};

test "wrap add" {
    try std.testing.expectEqual(@as(u32, 10), wrapAdd(9, 1, 24));
    try std.testing.expectEqual(@as(u32, 23), wrapAdd(0, -1, 24));
    try std.testing.expectEqual(@as(u32, 0), wrapAdd(59, 1, 60));
    try std.testing.expectEqual(@as(u32, 58), wrapAdd(59, -1, 60));
}
