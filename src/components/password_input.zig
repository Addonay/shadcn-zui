//! PasswordInput — Mantine's input with a reveal toggle.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");

/// Static dot string; callers slice to the value length (pure; unit-tested).
pub const mask: []const u8 = "....................";

pub fn maskFor(len: usize) []const u8 {
    const clamped = @min(len, mask.len);
    return mask[0..clamped];
}

pub const PasswordInput = struct {
    value_text: []const u8,
    showing: bool = false,
    /// Toggled when the eye button is pressed.
    on_toggle: ?zui.elements.Listener = null,

    pub fn init(value_text: []const u8) PasswordInput {
        return .{ .value_text = value_text };
    }

    pub fn isShowing(self: PasswordInput, value: bool) PasswordInput {
        var copy = self;
        copy.showing = value;
        return copy;
    }

    pub fn onToggle(self: PasswordInput, listener: zui.elements.Listener) PasswordInput {
        var copy = self;
        copy.on_toggle = listener;
        return copy;
    }

    pub fn render(self: PasswordInput) zui.Element {
        const display: []const u8 = if (self.showing) self.value_text else maskFor(self.value_text.len);
        var row = zui.div().flex_row().items_center().gap(8).h(38).px(12)
            .rounded_lg().bg(theme.background)
            .border_1().border_color(theme.input_border)
            .child(support.label(display, 14, theme.foreground))
            .child(zui.spacer());
        var eye = zui.div().size(24).flex_row().items_center().justify_center()
            .rounded(6).hover_bg(theme.accent)
            .child(icon_component.render(if (self.showing) .eye_off else .eye, 15, theme.muted_foreground));
        if (self.on_toggle) |listener| {
            eye = eye.cursor_pointer().on_click(listener);
        }
        return row.child(eye);
    }
};

test "mask length matches value length" {
    try std.testing.expectEqual(@as(usize, 4), maskFor(4).len);
    try std.testing.expectEqual(@as(usize, 20), maskFor(30).len);
    try std.testing.expectEqualStrings("...", maskFor(3));
}
