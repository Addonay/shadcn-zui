//! Questionnaire — shadcn's paged form flow: step title, fields, nav.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const button_component = @import("button.zig");

/// Progress for a step index over the total (pure; unit-tested).
pub fn progress(current: usize, total: usize) f32 {
    if (total == 0) return 0;
    return @as(f32, @floatFromInt(current)) / @as(f32, @floatFromInt(total));
}

test "progress" {
    try std.testing.expectEqual(@as(f32, 0.5), progress(2, 4));
    try std.testing.expectEqual(@as(f32, 0), progress(0, 0));
}

pub const Questionnaire = struct {
    /// The current step's body element — frame-local, set during render.
    step_title: []const u8,
    /// "Step 2 of 4" — the caller formats into its own buffer.
    step_label: []const u8 = "",
    step_description: []const u8 = "",
    body_value: zui.Element,
    step_index: usize = 0,
    step_total: usize = 1,
    on_back: ?zui.elements.Listener = null,
    on_next: ?zui.elements.Listener = null,

    pub fn init(step_title: []const u8, body: zui.Element) Questionnaire {
        return .{ .step_title = step_title, .body_value = body };
    }

    pub fn description(self: Questionnaire, text: []const u8) Questionnaire {
        var copy = self;
        copy.step_description = text;
        return copy;
    }

    pub fn step(self: Questionnaire, index: usize, total: usize) Questionnaire {
        var copy = self;
        copy.step_index = index;
        copy.step_total = total;
        return copy;
    }

    pub fn onBack(self: Questionnaire, listener: zui.elements.Listener) Questionnaire {
        var copy = self;
        copy.on_back = listener;
        return copy;
    }

    pub fn onNext(self: Questionnaire, listener: zui.elements.Listener) Questionnaire {
        var copy = self;
        copy.on_next = listener;
        return copy;
    }

    pub fn render(self: Questionnaire) zui.Element {
        var card = zui.div().flex_col().gap(12).p(16).w(420)
            .rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border)
            .child(support.label(self.step_label, 12, theme.muted_foreground))
            .child(support.strong(self.step_title, 18, theme.foreground));
        if (self.step_description.len > 0) {
            card = card.child(support.label(self.step_description, 13, theme.muted_foreground));
        }
        card = card.child(self.body_value);
        var footer = zui.div().flex_row().items_center().gap(8);
        if (self.on_back) |listener| {
            footer = footer.child(button_component.Button.init("Back")
                .variant(.outline).onClick(listener).render());
        }
        footer = footer.child(zui.spacer());
        if (self.on_next) |listener| {
            footer = footer.child(button_component.Button.init("Next")
                .variant(.primary).onClick(listener).render());
        }
        card = card.child(footer);
        return card;
    }
};

/// "Step 2 of 4" formatted into the caller's buffer (pure; unit-tested).
pub fn stepLabel(index: usize, total: usize, buf: []u8) []const u8 {
    return std.fmt.bufPrint(buf, "Step {d} of {d}", .{ index, total }) catch "";
}

test "progress math" {
    try std.testing.expectEqual(@as(f32, 0.5), progress(2, 4));
    try std.testing.expectEqual(@as(f32, 0), progress(0, 0));
}

test "step label" {
    var buf: [32]u8 = undefined;
    try std.testing.expectEqualStrings("Step 2 of 4", stepLabel(2, 4, &buf));
}
