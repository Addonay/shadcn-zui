//! Alert — shadcn/ui's callout block.

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Variant = enum { default, destructive, success, warning };

/// Default icon per variant (all exist in the bundled Lucide catalog).
pub fn defaultIcon(variant: Variant) icon_component.Name {
    return switch (variant) {
        .default => semantic.terminal,
        .destructive => semantic.info,
        .success => semantic.success,
        .warning => semantic.alert,
    };
}

/// Resolved palette (pure; unit-tested).
pub fn colors(variant: Variant) struct { border: zui.Color, icon: zui.Color, title: zui.Color } {
    return switch (variant) {
        .default => .{ .border = theme.border, .icon = theme.muted_foreground, .title = theme.foreground },
        .destructive => .{ .border = theme.destructive, .icon = theme.destructive, .title = theme.destructive },
        .success => .{ .border = theme.success, .icon = theme.success, .title = theme.foreground },
        .warning => .{ .border = theme.warning, .icon = theme.warning, .title = theme.foreground },
    };
}

pub const Alert = struct {
    title: []const u8 = "",
    description_value: ?[]const u8 = null,
    variant_value: Variant = .default,
    icon_value: ?icon_component.Name = null,

    pub fn init(title: []const u8) Alert {
        return .{ .title = title };
    }

    pub fn description(self: Alert, value: ?[]const u8) Alert {
        var copy = self;
        copy.description_value = value;
        return copy;
    }

    pub fn variant(self: Alert, value: Variant) Alert {
        var copy = self;
        copy.variant_value = value;
        return copy;
    }

    pub fn icon(self: Alert, name: icon_component.Name) Alert {
        var copy = self;
        copy.icon_value = name;
        return copy;
    }

    pub fn render(self: Alert) zui.Element {
        const palette = colors(self.variant_value);
        const glyph = self.icon_value orelse defaultIcon(self.variant_value);

        var body = zui.div().flex_col().gap(4)
            .child(support.strong(self.title, 14, palette.title));
        if (self.description_value) |text| {
            body = body.child(support.label(text, 13, theme.muted_foreground));
        }

        return zui.div().flex_row().items_center().gap(12).p(16).rounded_lg()
            .border_1().border_color(palette.border)
            .child(icon_component.render(glyph, 16, palette.icon))
            .child(body);
    }
};

const std = @import("std");

test "variants resolve colors and default icons" {
    const default = colors(.default);
    try std.testing.expectEqual(theme.border, default.border);
    try std.testing.expectEqual(theme.muted_foreground, default.icon);

    const destructive = colors(.destructive);
    try std.testing.expectEqual(theme.destructive, destructive.border);
    try std.testing.expectEqual(theme.destructive, destructive.icon);
    try std.testing.expectEqual(theme.destructive, destructive.title);

    try std.testing.expectEqual(semantic.terminal, defaultIcon(.default));
    try std.testing.expectEqual(semantic.info, defaultIcon(.destructive));
    try std.testing.expectEqual(semantic.alert, defaultIcon(.warning));
}
