//! Input — shadcn/ui's text-input chrome.
//!
//! This is a styled presentation box, **not** an editable field. Editable text
//! comes from zui's entity-based `zui.TextField`; this component renders the
//! value/placeholder and icon chrome around it and is the seam future field
//! integrations can mount inside.
//!
//! ```zig
//! Input.init()
//!     .placeholder("Email")
//!     .leadingIcon(semantic.mail)
//!     .render()
//! ```

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

pub const Metrics = struct {
    height: f32,
    padding_x: f32,
    radius: f32,
    gap: f32,
    text: f32,
    icon: f32,
};

/// shadcn's 36px control height with the reference's padding/radius rhythm.
pub fn metrics() Metrics {
    return .{ .height = 36, .padding_x = 12, .radius = 8, .gap = 8, .text = 14, .icon = 16 };
}

pub const Colors = struct {
    border: zui.Color,
    value: zui.Color,
    placeholder: zui.Color,
    icon: zui.Color,
};

pub fn colors(invalid: bool) Colors {
    return .{
        .border = if (invalid) theme.destructive else theme.input_border,
        .value = theme.foreground,
        .placeholder = theme.muted_foreground,
        .icon = theme.muted_foreground,
    };
}

pub const Input = struct {
    placeholder_text: []const u8 = "",
    value_text: ?[]const u8 = null,
    leading_icon: ?icon_component.Name = null,
    trailing_icon: ?icon_component.Name = null,
    width_value: ?f32 = null,
    disabled_value: bool = false,
    invalid_value: bool = false,

    pub fn init() Input {
        return .{};
    }

    pub fn placeholder(self: Input, text: []const u8) Input {
        var copy = self;
        copy.placeholder_text = text;
        return copy;
    }

    /// Non-null text is drawn in the foreground color; `null` falls back to the
    /// placeholder.
    pub fn value(self: Input, text: ?[]const u8) Input {
        var copy = self;
        copy.value_text = text;
        return copy;
    }

    pub fn leadingIcon(self: Input, name: icon_component.Name) Input {
        var copy = self;
        copy.leading_icon = name;
        return copy;
    }

    pub fn trailingIcon(self: Input, name: icon_component.Name) Input {
        var copy = self;
        copy.trailing_icon = name;
        return copy;
    }

    /// Optional fixed width; `null` stretches to the parent (`w_full`).
    pub fn width(self: Input, px: ?f32) Input {
        var copy = self;
        copy.width_value = px;
        return copy;
    }

    pub fn disabled(self: Input, flag: bool) Input {
        var copy = self;
        copy.disabled_value = flag;
        return copy;
    }

    /// Paints the border with `theme.destructive` (shadcn's `aria-invalid`).
    pub fn invalid(self: Input, flag: bool) Input {
        var copy = self;
        copy.invalid_value = flag;
        return copy;
    }

    pub fn render(self: Input) zui.Element {
        const m = metrics();
        const c = colors(self.invalid_value);

        var box = zui.div().flex_row().items_center()
            .h(m.height).px(m.padding_x).gap(m.gap)
            .rounded(m.radius).border_1().border_color(c.border);
        if (self.width_value) |px| {
            box = box.w(px);
        } else {
            box = box.w_full();
        }
        if (self.disabled_value) box = box.opacity(0.5);

        if (self.leading_icon) |name| {
            box = box.child(icon_component.render(name, m.icon, c.icon));
        }
        if (self.value_text) |text| {
            box = box.child(support.label(text, m.text, c.value));
        } else {
            box = box.child(support.label(self.placeholder_text, m.text, c.placeholder));
        }
        if (self.trailing_icon) |name| {
            box = box.child(icon_component.render(name, m.icon, c.icon));
        }
        return box;
    }
};

const std = @import("std");

test "metrics match shadcn input chrome" {
    const m = metrics();
    try std.testing.expectEqual(@as(f32, 36), m.height);
    try std.testing.expectEqual(@as(f32, 12), m.padding_x);
    try std.testing.expectEqual(@as(f32, 8), m.radius);
    try std.testing.expectEqual(@as(f32, 8), m.gap);
    try std.testing.expectEqual(@as(f32, 14), m.text);
    try std.testing.expectEqual(@as(f32, 16), m.icon);
}

test "invalid swaps the border to destructive" {
    const normal = colors(false);
    try std.testing.expectEqual(theme.input_border, normal.border);
    try std.testing.expectEqual(theme.foreground, normal.value);
    try std.testing.expectEqual(theme.muted_foreground, normal.placeholder);
    try std.testing.expectEqual(theme.muted_foreground, normal.icon);

    const invalid = colors(true);
    try std.testing.expectEqual(theme.destructive, invalid.border);
}

test "builder methods return updated copies" {
    const base = Input.init().placeholder("Email");
    try std.testing.expectEqualStrings("Email", base.placeholder_text);
    try std.testing.expect(base.value_text == null);
    try std.testing.expect(base.width_value == null);
    try std.testing.expect(base.leading_icon == null);

    const configured = base
        .value("me@example.com")
        .leadingIcon(semantic.mail)
        .trailingIcon(semantic.search)
        .width(240)
        .invalid(true)
        .disabled(true);
    try std.testing.expectEqualStrings("Email", configured.placeholder_text);
    try std.testing.expectEqualStrings("me@example.com", configured.value_text.?);
    try std.testing.expect(configured.leading_icon == semantic.mail);
    try std.testing.expect(configured.trailing_icon == semantic.search);
    try std.testing.expectEqual(@as(f32, 240), configured.width_value.?);
    try std.testing.expect(configured.invalid_value);
    try std.testing.expect(configured.disabled_value);
    // The original stays untouched (value semantics).
    try std.testing.expect(base.value_text == null);
    try std.testing.expect(base.width_value == null);
    try std.testing.expect(!base.invalid_value);
}
