//! Combobox — gpui-kit/shadcn's filterable select. `filter` is the pure
//! core (case-insensitive substring matching); the panel is the app's
//! popover with `list.Item` rows.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

/// Case-insensitive substring match (pure; unit-tested).
pub fn matches(label: []const u8, query: []const u8) bool {
    if (query.len == 0) return true;
    var hay_buf: [128]u8 = undefined;
    var needle_buf: [64]u8 = undefined;
    const hay = lower(label, &hay_buf) orelse return false;
    const needle = lower(query, &needle_buf) orelse return false;
    return std.mem.indexOf(u8, hay, needle) != null;
}

fn lower(text: []const u8, buf: []u8) ?[]const u8 {
    if (text.len > buf.len) return null;
    for (text, 0..) |c, i| buf[i] = std.ascii.toLower(c);
    return buf[0..text.len];
}

pub const Combobox = struct {
    /// Display value; borrowed until paint.
    value_text: []const u8 = "",
    placeholder_text: []const u8 = "",
    on_open: ?zui.elements.Listener = null,

    pub fn init() Combobox {
        return .{};
    }

    pub fn value(self: Combobox, text: []const u8) Combobox {
        var copy = self;
        copy.value_text = text;
        return copy;
    }

    pub fn placeholder(self: Combobox, text: []const u8) Combobox {
        var copy = self;
        copy.placeholder_text = text;
        return copy;
    }

    pub fn onOpen(self: Combobox, listener: zui.elements.Listener) Combobox {
        var copy = self;
        copy.on_open = listener;
        return copy;
    }

    pub fn render(self: Combobox) zui.Element {
        var row = zui.div().flex_row().items_center().gap(8).h(38).px(12)
            .rounded_lg().bg(theme.background)
            .border_1().border_color(theme.input_border)
            .hover_bg(theme.accent)
            .child(icon_component.render(semantic.search, 16, theme.muted_foreground))
            .child(support.label(
            if (self.value_text.len > 0) self.value_text else self.placeholder_text,
            14,
            if (self.value_text.len > 0) theme.foreground else theme.muted_foreground,
        ));
        if (self.on_open) |listener| row = row.cursor_pointer().on_click(listener);
        return row;
    }
};

test "matches is case-insensitive and empty-query-all" {
    try std.testing.expect(matches("Eddie Lake", "eddie"));
    try std.testing.expect(matches("Eddie Lake", "lake"));
    try std.testing.expect(!matches("Eddie Lake", "zzz"));
    try std.testing.expect(matches("anything", ""));
}
