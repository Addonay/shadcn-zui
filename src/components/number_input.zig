//! NumberInput — gpui-kit/Mantine/Ant's value stepper.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const button_component = @import("button.zig");

/// Value after a step, clamped and snapped to `step` increments (pure).
pub fn stepped(value: f32, delta: f32, step: f32, min: f32, max: f32) f32 {
    const raw = value + delta * (if (step > 0) step else 1);
    var result = @max(min, @min(raw, max));
    if (step > 0) {
        result = min + @round((result - min) / step) * step;
        result = @max(min, @min(result, max));
    }
    return result;
}

pub const NumberInput = struct {
    /// Formatted value; borrowed until paint ("40", "1,234", ...).
    value_text: []const u8,
    on_increment: ?zui.Listener = null,
    on_decrement: ?zui.Listener = null,
    disabled_value: bool = false,

    pub fn init(value_text: []const u8) NumberInput {
        return .{ .value_text = value_text };
    }

    pub fn onIncrement(self: NumberInput, listener: zui.Listener) NumberInput {
        var copy = self;
        copy.on_increment = listener;
        return copy;
    }

    pub fn onDecrement(self: NumberInput, listener: zui.Listener) NumberInput {
        var copy = self;
        copy.on_decrement = listener;
        return copy;
    }

    pub fn disabled(self: NumberInput, value: bool) NumberInput {
        var copy = self;
        copy.disabled_value = value;
        return copy;
    }

    fn stepperButton(self: NumberInput, name: icon_component.Name, listener: ?zui.Listener) zui.Element {
        var slot = zui.div().flex_1().h(20).flex_row().items_center().justify_center()
            .hover_bg(theme.accent);
        slot = slot.child(icon_component.render(name, 12, theme.muted_foreground));
        if (listener) |value| {
            if (!self.disabled_value) slot = slot.cursor_pointer().on_click(value);
        }
        return slot;
    }

    pub fn render(self: NumberInput) zui.Element {
        const steppers = zui.div().flex_col().size(20).rounded(6)
            .border_1().border_color(theme.border)
            .child(self.stepperButton(.chevron_up, self.on_increment))
            .child(self.stepperButton(.chevron_down, self.on_decrement));
        return zui.div().flex_row().items_center().gap(8).h(38).px(12)
            .rounded_lg().bg(theme.background)
            .border_1().border_color(theme.input_border)
            .child(zui.div().flex_1().child(support.label(self.value_text, 14, theme.foreground)))
            .child(steppers);
    }
};

test "stepped clamps and snaps" {
    try std.testing.expectEqual(@as(f32, 45), stepped(40, 1, 5, 0, 100));
    try std.testing.expectEqual(@as(f32, 35), stepped(40, -1, 5, 0, 100));
    try std.testing.expectEqual(@as(f32, 100), stepped(99, 1, 5, 0, 100));
    try std.testing.expectEqual(@as(f32, 0), stepped(1, -1, 5, 0, 100));
    try std.testing.expectEqual(@as(f32, 41), stepped(40, 1, 0, 0, 100));
}
