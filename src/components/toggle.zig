//! Toggle — a button with a pressed state (shadcn Toggle).

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Size = enum { sm, md };

pub const Metrics = struct {
    height: f32,
    padding_x: f32,
    text: f32,
    icon: f32,
    radius: f32,
};

pub fn metrics(size: Size) Metrics {
    return switch (size) {
        .sm => .{ .height = 28, .padding_x = 10, .text = 12, .icon = 14, .radius = 8 },
        .md => .{ .height = 32, .padding_x = 12, .text = 13, .icon = 16, .radius = 8 },
    };
}

pub const Colors = struct {
    background: ?zui.Color,
    hover: ?zui.Color,
    border: zui.Color,
    foreground: zui.Color,
};

/// Pressed and unpressed palettes (pure; unit-tested).
pub fn colors(pressed: bool) Colors {
    return if (pressed)
        .{ .background = theme.accent, .hover = theme.accent_hover, .border = theme.accent, .foreground = theme.foreground }
    else
        .{ .background = null, .hover = theme.accent, .border = theme.border, .foreground = theme.foreground };
}

pub const Toggle = struct {
    text: []const u8 = "",
    pressed_value: bool = false,
    size_value: Size = .md,
    icon_value: ?icon_component.Name = null,
    disabled_value: bool = false,
    listener: ?zui.elements.Listener = null,

    pub fn init(text: []const u8) Toggle {
        return .{ .text = text };
    }

    /// Icon-only when the label is empty.
    pub fn iconOnly(name: icon_component.Name) Toggle {
        return .{ .text = "", .icon_value = name };
    }

    pub fn icon(self: Toggle, name: icon_component.Name) Toggle {
        var copy = self;
        copy.icon_value = name;
        return copy;
    }

    pub fn pressed(self: Toggle, value: bool) Toggle {
        var copy = self;
        copy.pressed_value = value;
        return copy;
    }

    pub fn size(self: Toggle, value: Size) Toggle {
        var copy = self;
        copy.size_value = value;
        return copy;
    }

    pub fn disabled(self: Toggle, value: bool) Toggle {
        var copy = self;
        copy.disabled_value = value;
        return copy;
    }

    pub fn onToggle(self: Toggle, listener: zui.elements.Listener) Toggle {
        var copy = self;
        copy.listener = listener;
        return copy;
    }

    pub fn render(self: Toggle) zui.Element {
        const m = metrics(self.size_value);
        const c = colors(self.pressed_value);

        var toggle = zui.div().flex_row().items_center().justify_center()
            .h(m.height).px(m.padding_x).rounded(m.radius).border_1();
        if (c.background) |background| toggle = toggle.bg(background);
        toggle = toggle.border_color(c.border);
        if (c.hover) |hover| toggle = toggle.hover_bg(hover);
        if (!self.disabled_value) {
            toggle = toggle.cursor_pointer();
            if (self.listener) |listener| toggle = toggle.on_click(listener);
        } else {
            toggle = toggle.opacity(0.5);
        }
        if (self.icon_value) |name| {
            toggle = toggle.child(icon_component.render(name, m.icon, c.foreground));
        }
        if (self.text.len > 0) {
            toggle = toggle.child(support.label(self.text, m.text, c.foreground));
        }
        return toggle;
    }
};

const std = @import("std");

test "toggle metrics and palettes" {
    try std.testing.expectEqual(@as(f32, 28), metrics(.sm).height);
    try std.testing.expectEqual(@as(f32, 32), metrics(.md).height);

    const unpressed = colors(false);
    try std.testing.expect(unpressed.background == null);
    try std.testing.expectEqual(theme.border, unpressed.border);

    const pressed = colors(true);
    try std.testing.expectEqual(theme.accent, pressed.background.?);
    try std.testing.expectEqual(theme.accent_hover, pressed.hover.?);
}
