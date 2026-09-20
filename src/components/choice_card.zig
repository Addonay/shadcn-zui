//! ChoiceCard — shadcn's checkbox-card / radio-card: a card-sized row with
//! a control, title and description.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");

pub const Kind = enum { checkbox, radio };

/// Surface for the selected state (pure; unit-tested).
pub fn surface(selected: bool) struct { bg: zui.Color, border: zui.Color } {
    if (selected) return .{ .bg = theme.accent, .border = theme.ring };
    return .{ .bg = theme.background, .border = theme.border };
}

pub const ChoiceCard = struct {
    kind: Kind = .checkbox,
    title_text: []const u8,
    description_text: ?[]const u8 = null,
    selected: bool = false,
    on_click: ?zui.Listener = null,

    pub fn init(title_text: []const u8) ChoiceCard {
        return .{ .title_text = title_text };
    }

    pub fn asRadio(self: ChoiceCard) ChoiceCard {
        var copy = self;
        copy.kind = .radio;
        return copy;
    }

    pub fn description(self: ChoiceCard, text: []const u8) ChoiceCard {
        var copy = self;
        copy.description_text = text;
        return copy;
    }

    pub fn isSelected(self: ChoiceCard, value: bool) ChoiceCard {
        var copy = self;
        copy.selected = value;
        return copy;
    }

    pub fn onClick(self: ChoiceCard, listener: zui.Listener) ChoiceCard {
        var copy = self;
        copy.on_click = listener;
        return copy;
    }

    fn control(self: ChoiceCard) zui.Element {
        if (self.kind == .radio) {
            const dot = zui.div().size(6).rounded_full().bg(theme.primary);
            return zui.div().size(16).rounded_full().bg(theme.background)
                .border_1().border_color(if (self.selected) theme.primary else theme.input_border)
                .flex_row().items_center().justify_center()
                .child(zui.when(self.selected, dot));
        }
        const check = zui.div().size(10).rounded(2).bg(theme.primary_foreground)
            .child(support.label("✓", 8, theme.primary));
        return zui.div().size(16).rounded(4).bg(theme.background)
            .border_1().border_color(if (self.selected) theme.primary else theme.input_border)
            .flex_row().items_center().justify_center()
            .child(zui.when(self.selected, check));
    }

    pub fn render(self: ChoiceCard) zui.Element {
        const pair = surface(self.selected);
        var card = zui.div().flex_row().items_start().gap(10).p(12)
            .rounded_lg().bg(pair.bg)
            .border_1().border_color(pair.border);
        card = card.child(self.control());
        var col = zui.div().flex_col().gap(2).flex_1()
            .child(support.strong(self.title_text, 14, theme.foreground));
        if (self.description_text) |text| {
            col = col.child(support.label(text, 13, theme.muted_foreground));
        }
        card = card.child(col);
        if (self.on_click) |listener| {
            card = card.cursor_pointer().on_click(listener);
        }
        return card;
    }
};

const std = @import("std");

test "surface follows selection" {
    const on = surface(true);
    try std.testing.expectEqual(theme.accent, on.bg);
    const off = surface(false);
    try std.testing.expectEqual(theme.background, off.bg);
}
