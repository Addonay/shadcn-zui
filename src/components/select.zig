//! Select — shadcn/HeroUI's select: a styled trigger + option rows.
//! The panel renders at the app root inside a Popover; this file provides
//! the trigger chrome and the option row.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

pub const trigger_height: f32 = 36;

/// Trigger chrome (pure; unit-tested).
pub fn triggerStyle(has_value: bool) zui.Color {
    return if (has_value) theme.foreground else theme.muted_foreground;
}

pub const Select = struct {
    /// Shown when nothing is selected.
    placeholder_text: []const u8,
    /// The current label ("Eddie Lake"); borrowed until paint.
    value_text: ?[]const u8 = null,
    on_open: ?zui.elements.Listener = null,
    disabled: bool = false,

    pub fn init(placeholder_text: []const u8) Select {
        return .{ .placeholder_text = placeholder_text };
    }

    pub fn value(self: Select, text: []const u8) Select {
        var copy = self;
        copy.value_text = text;
        return copy;
    }

    pub fn onOpen(self: Select, listener: zui.elements.Listener) Select {
        var copy = self;
        copy.on_open = listener;
        return copy;
    }

    pub fn render(self: Select) zui.Element {
        var row = zui.div().flex_row().items_center().gap(8).h(38).px(12)
            .rounded_lg().bg(theme.background)
            .border_1().border_color(theme.input_border);
        row = row.hover_bg(theme.accent);
        if (self.on_open != null and !self.disabled) row = row.cursor_pointer();
        if (self.on_open) |listener| {
            if (!self.disabled) row = row.on_click(listener);
        }
        row = row.child(support.label(
            self.value_text orelse self.placeholder_text,
            14,
            triggerStyle(self.value_text != null),
        ));
        row = row.child(zui.spacer());
        row = row.child(icon_component.render(semantic.chevron_down, 16, theme.muted_foreground));
        return row;
    }
};

/// One option row for the select panel (reuse `list.Item` for panels with
/// icons; this is the radio-dot variant).
pub const Option = struct {
    label: []const u8,
    selected: bool = false,
    on_click: ?zui.elements.Listener = null,

    pub fn render(self: Option) zui.Element {
        var row = zui.div().flex_row().items_center().gap(8).h(32).px(8).rounded(6)
            .hover_bg(theme.accent);
        if (self.on_click) |listener| {
            row = row.cursor_pointer().on_click(listener);
        }
        const ring = zui.div().size(14).rounded_full()
            .bg(if (self.selected) theme.primary else theme.background)
            .border_1().border_color(if (self.selected) theme.primary else theme.input_border);
        if (self.selected) {
            row = row.child(zui.div().flex_row().items_center().justify_center()
                .size(14).child(zui.div().size(6).rounded_full().bg(theme.primary_foreground)));
        } else {
            row = row.child(ring);
        }
        row = row.child(support.label(self.label, 14, theme.body));
        return row;
    }
};

const std = @import("std");

test "trigger chrome" {
    try std.testing.expectEqual(theme.foreground, triggerStyle(true));
    try std.testing.expectEqual(theme.muted_foreground, triggerStyle(false));
}
