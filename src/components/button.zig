//! Button — shadcn/ui variants on top of zui's container element.
//!
//! ```zig
//! Button.init("Save changes")
//!     .variant(.primary)
//!     .size(.md)
//!     .leadingIcon(.check)
//!     .onClick(cx.listener(State, save))
//!     .render()
//! ```
//!
//! Listeners are built by the caller from its own `Context`, so the same
//! component works for any app state type.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");

pub const Variant = enum { primary, secondary, destructive, outline, ghost, link };
pub const Size = enum { sm, md, lg, icon };

pub const Metrics = struct {
    height: f32,
    padding_x: f32,
    text: f32,
    icon: f32,
    gap: f32,
    radius: f32,
};

/// shadcn/ui's control heights, rounded to the reference's 4px rhythm.
pub fn metrics(size: Size) Metrics {
    return switch (size) {
        .sm => .{ .height = 32, .padding_x = 12, .text = 13, .icon = 14, .gap = 6, .radius = theme.radius_sm },
        .md => .{ .height = 36, .padding_x = 16, .text = 14, .icon = 16, .gap = 8, .radius = theme.radius_sm },
        .lg => .{ .height = 40, .padding_x = 24, .text = 14, .icon = 16, .gap = 8, .radius = theme.radius_sm },
        .icon => .{ .height = 36, .padding_x = 0, .text = 14, .icon = 16, .gap = 0, .radius = theme.radius_sm },
    };
}

const Colors = struct {
    background: ?zui.Color,
    hover_background: ?zui.Color,
    border: ?zui.Color,
    hover_border: ?zui.Color,
    foreground: zui.Color,
};

pub fn colors(variant: Variant) Colors {
    return switch (variant) {
        .primary => .{
            .background = theme.primary,
            .hover_background = theme.primary_hover,
            .border = null,
            .hover_border = null,
            .foreground = theme.primary_foreground,
        },
        .secondary => .{
            .background = theme.secondary,
            .hover_background = theme.secondary_hover,
            .border = null,
            .hover_border = null,
            .foreground = theme.secondary_foreground,
        },
        .destructive => .{
            .background = theme.destructive,
            .hover_background = theme.destructive_hover,
            .border = null,
            .hover_border = null,
            .foreground = theme.destructive_foreground,
        },
        .outline => .{
            .background = null,
            .hover_background = theme.accent,
            .border = theme.border,
            .hover_border = theme.border_strong,
            .foreground = theme.foreground,
        },
        .ghost => .{
            .background = null,
            .hover_background = theme.accent,
            .border = null,
            .hover_border = null,
            .foreground = theme.foreground,
        },
        .link => .{
            .background = null,
            .hover_background = null,
            .border = null,
            .hover_border = null,
            .foreground = theme.foreground,
        },
    };
}

pub const Button = struct {
    text: []const u8,
    variant_value: Variant = .primary,
    size_value: Size = .md,
    disabled_value: bool = false,
    leading_icon: ?icon_component.Name = null,
    trailing_icon: ?icon_component.Name = null,
    listener: ?zui.elements.Listener = null,

    pub fn init(text: []const u8) Button {
        return .{ .text = text };
    }

    pub fn variant(self: Button, value: Variant) Button {
        var copy = self;
        copy.variant_value = value;
        return copy;
    }

    pub fn size(self: Button, value: Size) Button {
        var copy = self;
        copy.size_value = value;
        return copy;
    }

    pub fn disabled(self: Button, value: bool) Button {
        var copy = self;
        copy.disabled_value = value;
        return copy;
    }

    pub fn leadingIcon(self: Button, name: icon_component.Name) Button {
        var copy = self;
        copy.leading_icon = name;
        return copy;
    }

    pub fn trailingIcon(self: Button, name: icon_component.Name) Button {
        var copy = self;
        copy.trailing_icon = name;
        return copy;
    }

    pub fn onClick(self: Button, listener: zui.elements.Listener) Button {
        var copy = self;
        copy.listener = listener;
        return copy;
    }

    pub fn render(self: Button) zui.Element {
        const m = metrics(self.size_value);
        const c = colors(self.variant_value);

        var button = zui.div().flex_row().items_center().justify_center()
            .h(m.height).px(m.padding_x).gap(m.gap).rounded_lg();
        if (c.background) |value| button = button.bg(value);
        if (c.hover_background) |value| button = button.hover_bg(value);
        if (c.border) |value| {
            button = button.border_1().border_color(value);
            if (c.hover_border) |hover| button = button.hover_border(hover);
        }
        if (!self.disabled_value) {
            button = button.cursor_pointer();
            if (self.listener) |listener| button = button.on_click(listener);
        } else {
            button = button.opacity(0.5);
        }

        if (self.leading_icon) |name| {
            button = button.child(icon_component.render(name, m.icon, c.foreground));
        }
        button = button.child(support.strong(self.text, m.text, c.foreground));
        if (self.trailing_icon) |name| {
            button = button.child(icon_component.render(name, m.icon, c.foreground));
        }
        return button;
    }
};

/// A square, icon-only button (gpui-kit's `button-icon`).
pub const IconButton = struct {
    name: icon_component.Name,
    variant_value: Variant = .ghost,
    size_value: f32 = 36,
    icon_px: f32 = 16,
    disabled_value: bool = false,
    listener: ?zui.elements.Listener = null,

    pub fn init(name: icon_component.Name) IconButton {
        return .{ .name = name };
    }

    pub fn variant(self: IconButton, value: Variant) IconButton {
        var copy = self;
        copy.variant_value = value;
        return copy;
    }

    pub fn size(self: IconButton, square: f32, icon_px: f32) IconButton {
        var copy = self;
        copy.size_value = square;
        copy.icon_px = icon_px;
        return copy;
    }

    pub fn disabled(self: IconButton, value: bool) IconButton {
        var copy = self;
        copy.disabled_value = value;
        return copy;
    }

    pub fn onClick(self: IconButton, listener: zui.elements.Listener) IconButton {
        var copy = self;
        copy.listener = listener;
        return copy;
    }

    pub fn render(self: IconButton) zui.Element {
        const c = colors(self.variant_value);
        var button = zui.div().flex_row().items_center().justify_center()
            .size(self.size_value).rounded_lg();
        if (c.background) |value| button = button.bg(value);
        if (c.hover_background) |value| button = button.hover_bg(value);
        if (c.border) |value| {
            button = button.border_1().border_color(value);
            if (c.hover_border) |hover| button = button.hover_border(hover);
        }
        if (!self.disabled_value) {
            button = button.cursor_pointer();
            if (self.listener) |listener| button = button.on_click(listener);
        } else {
            button = button.opacity(0.5);
        }
        return button.child(icon_component.render(self.name, self.icon_px, c.foreground));
    }
};

const std = @import("std");

test "sizes follow shadcn control heights" {
    try std.testing.expectEqual(@as(f32, 32), metrics(.sm).height);
    try std.testing.expectEqual(@as(f32, 36), metrics(.md).height);
    try std.testing.expectEqual(@as(f32, 40), metrics(.lg).height);
    try std.testing.expectEqual(@as(f32, 36), metrics(.icon).height);
}

test "variants resolve expected colors" {
    const primary = colors(.primary);
    try std.testing.expectEqual(theme.primary, primary.background.?);
    try std.testing.expectEqual(theme.primary_foreground, primary.foreground);

    const outline = colors(.outline);
    try std.testing.expect(outline.background == null);
    try std.testing.expectEqual(theme.border, outline.border.?);

    const ghost = colors(.ghost);
    try std.testing.expectEqual(theme.accent, ghost.hover_background.?);
}
