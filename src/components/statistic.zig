//! Statistic — Ant/Mantine's big number with label, delta and icon.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");
const icon_component = @import("icon/root.zig");

pub const Delta = enum { up, down, flat };

/// Delta accent color (pure; unit-tested).
pub fn deltaColor(delta: Delta) zui.Color {
    return switch (delta) {
        .up => theme.success,
        .down => theme.destructive,
        .flat => theme.muted_foreground,
    };
}

pub const Statistic = struct {
    value_text: []const u8,
    label_text: []const u8 = "",
    delta_text: ?[]const u8 = null,
    delta_kind: Delta = .flat,
    leading_icon: ?icon_component.Name = null,
    sub_text: ?[]const u8 = null,

    pub fn init(value_text: []const u8) Statistic {
        return .{ .value_text = value_text };
    }

    pub fn label(self: Statistic, text: []const u8) Statistic {
        var copy = self;
        copy.label_text = text;
        return copy;
    }

    pub fn delta(self: Statistic, text: []const u8, kind: Delta) Statistic {
        var copy = self;
        copy.delta_text = text;
        copy.delta_kind = kind;
        return copy;
    }

    pub fn icon(self: Statistic, name: icon_component.Name) Statistic {
        var copy = self;
        copy.leading_icon = name;
        return copy;
    }

    pub fn sub(self: Statistic, text: []const u8) Statistic {
        var copy = self;
        copy.sub_text = text;
        return copy;
    }

    pub fn render(self: Statistic) zui.Element {
        var row = zui.div().flex_row().items_center().gap(12);
        if (self.leading_icon) |name| {
            row = row.child(zui.div().size(36).flex_row().items_center().justify_center()
                .rounded_lg().bg(theme.accent)
                .child(icon_component.render(name, 18, theme.muted_foreground)));
        }
        var col = zui.div().flex_col().gap(2)
            .child(support.label(self.label_text, 12, theme.muted_foreground))
            .child(support.strong(self.value_text, 22, theme.foreground));
        var meta = zui.div().flex_row().items_center().gap(6);
        if (self.delta_text) |text| {
            meta = meta.child(support.label(text, 12, deltaColor(self.delta_kind)));
        }
        if (self.sub_text) |text| {
            meta = meta.child(support.label(text, 12, theme.muted_foreground));
        }
        if (self.delta_text != null or self.sub_text != null) col = col.child(meta);
        row = row.child(col);
        return row;
    }
};

const std = @import("std");

test "delta colors" {
    try std.testing.expectEqual(theme.success, deltaColor(.up));
    try std.testing.expectEqual(theme.destructive, deltaColor(.down));
    try std.testing.expectEqual(theme.muted_foreground, deltaColor(.flat));
}
