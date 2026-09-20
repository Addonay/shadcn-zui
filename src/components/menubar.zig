//! Menubar — shadcn/gpui-kit's horizontal bar of menu triggers. Triggers are
//! inline; the open menu renders at the app root (DropdownMenu at pointer).

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");

pub const item_height: f32 = 30;
pub const item_padding_x: f32 = 10;

/// One trigger slot. `active` highlights the open menu.
pub const Trigger = struct {
    label: []const u8,
    active: bool = false,
    on_click: ?zui.elements.Listener = null,
};

/// Trigger chrome for a state (pure; unit-tested).
pub fn triggerStyle(active: bool) struct { bg: ?zui.Color, foreground: zui.Color } {
    return if (active)
        .{ .bg = theme.accent, .foreground = theme.foreground }
    else
        .{ .bg = null, .foreground = theme.body };
}

pub const Menubar = struct {
    triggers: []const Trigger,

    pub fn init(triggers: []const Trigger) Menubar {
        return .{ .triggers = triggers };
    }

    pub fn render(self: Menubar) zui.Element {
        var row = zui.div().flex_row().items_center().gap(2).p(4)
            .rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border);
        for (self.triggers) |trigger| {
            const style = triggerStyle(trigger.active);
            var slot = zui.div().flex_row().items_center().h(item_height).px(item_padding_x)
                .rounded(6);
            if (style.bg) |color| slot = slot.bg(color);
            slot = slot.hover_bg(theme.accent);
            if (trigger.on_click != null) slot = slot.cursor_pointer();
            if (trigger.on_click) |listener| slot = slot.on_click(listener);
            row = row.child(slot.child(support.label(trigger.label, 13, style.foreground)));
        }
        return row;
    }
};

const std = @import("std");

test "trigger styles" {
    const active = triggerStyle(true);
    try std.testing.expectEqual(theme.accent, active.bg.?);
    const idle = triggerStyle(false);
    try std.testing.expectEqual(@as(?zui.Color, null), idle.bg);
}
