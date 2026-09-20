//! Checkbox — shadcn/ui's square check control.
//!
//! ```zig
//! Checkbox.init()
//!     .checked(row.selected)
//!     .onToggle(cx.listener(State, toggleRow))
//!     .render()
//! ```
//!
//! Listeners are built by the caller from its own `Context`, so the same
//! component works for any app state type.

const zui = @import("zui");

const theme = @import("../theme.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

/// The dashboard's 16px checkbox square.
pub const default_size: f32 = 16;
pub const corner_radius: f32 = 4;
/// The check glyph is drawn slightly smaller than the box so its stroke clears
/// the 1px border.
pub const glyph_scale: f32 = 0.7;

pub const Metrics = struct {
    size: f32,
    radius: f32,
    glyph: f32,
};

pub fn metrics(size: f32) Metrics {
    return .{ .size = size, .radius = corner_radius, .glyph = size * glyph_scale };
}

pub const Colors = struct {
    /// `null` means transparent (no background painted).
    background: ?zui.Color,
    border: zui.Color,
    glyph: zui.Color,
};

pub fn colors(checked: bool) Colors {
    if (checked) {
        return .{
            .background = theme.primary,
            .border = theme.primary,
            .glyph = theme.primary_foreground,
        };
    }
    return .{
        .background = null,
        .border = theme.border_strong,
        .glyph = theme.primary_foreground,
    };
}

pub const Checkbox = struct {
    checked_value: bool = false,
    disabled_value: bool = false,
    size_value: f32 = default_size,
    listener: ?zui.elements.Listener = null,

    pub fn init() Checkbox {
        return .{};
    }

    pub fn checked(self: Checkbox, value: bool) Checkbox {
        var copy = self;
        copy.checked_value = value;
        return copy;
    }

    pub fn disabled(self: Checkbox, value: bool) Checkbox {
        var copy = self;
        copy.disabled_value = value;
        return copy;
    }

    /// Optional size override; `null` keeps the 16px default.
    pub fn size(self: Checkbox, value: ?f32) Checkbox {
        var copy = self;
        if (value) |px| copy.size_value = px;
        return copy;
    }

    pub fn onToggle(self: Checkbox, listener: zui.elements.Listener) Checkbox {
        var copy = self;
        copy.listener = listener;
        return copy;
    }

    pub fn render(self: Checkbox) zui.Element {
        const m = metrics(self.size_value);
        const c = colors(self.checked_value);

        var box = zui.div().flex_row().items_center().justify_center()
            .size(m.size).rounded(m.radius).border_1().border_color(c.border);
        if (c.background) |value| box = box.bg(value);

        if (self.disabled_value) {
            box = box.opacity(0.5);
        } else {
            box = box.cursor_pointer();
            if (self.listener) |listener| box = box.on_click(listener);
        }

        if (self.checked_value) {
            box = box.child(icon_component.render(semantic.check, m.glyph, c.glyph));
        }
        return box;
    }
};

const std = @import("std");

test "default metrics match the dashboard checkbox" {
    const m = metrics(default_size);
    try std.testing.expectEqual(@as(f32, 16), m.size);
    try std.testing.expectEqual(@as(f32, 4), m.radius);
    try std.testing.expectEqual(@as(f32, 11.2), m.glyph);
}

test "metrics scale the glyph with the box" {
    try std.testing.expectEqual(@as(f32, 20), metrics(20).size);
    try std.testing.expectApproxEqAbs(@as(f32, 14), metrics(20).glyph, 0.0001);
}

test "colors resolve checked and unchecked states" {
    const on = colors(true);
    try std.testing.expectEqual(theme.primary, on.background.?);
    try std.testing.expectEqual(theme.primary, on.border);
    try std.testing.expectEqual(theme.primary_foreground, on.glyph);

    const off = colors(false);
    try std.testing.expect(off.background == null);
    try std.testing.expectEqual(theme.border_strong, off.border);
}

test "builder methods return updated copies" {
    const base = Checkbox.init();
    try std.testing.expect(!base.checked_value);
    try std.testing.expect(!base.disabled_value);
    try std.testing.expectEqual(default_size, base.size_value);
    try std.testing.expect(base.listener == null);

    const configured = base.checked(true).disabled(true).size(20);
    try std.testing.expect(configured.checked_value);
    try std.testing.expect(configured.disabled_value);
    try std.testing.expectEqual(@as(f32, 20), configured.size_value);
    // The original stays untouched (value semantics).
    try std.testing.expect(!base.checked_value);

    try std.testing.expectEqual(default_size, base.size(null).size_value);
}
