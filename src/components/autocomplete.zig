//! Autocomplete — free text + suggestion rows (Mantine/Ant/HeroUI).
//! Suggestion matching is the same pure core as `combobox.matches`; this
//! file adds the input-with-suggestions presentation.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");

pub const Autocomplete = struct {
    /// The typed value; borrowed until paint.
    value_text: []const u8 = "",
    placeholder_text: []const u8 = "",
    /// Triggered on activate (enter/click) with the current text.
    on_activate: ?zui.Listener = null,

    pub fn init() Autocomplete {
        return .{};
    }

    pub fn value(self: Autocomplete, text: []const u8) Autocomplete {
        var copy = self;
        copy.value_text = text;
        return copy;
    }

    pub fn placeholder(self: Autocomplete, text: []const u8) Autocomplete {
        var copy = self;
        copy.placeholder_text = text;
        return copy;
    }

    pub fn onActivate(self: Autocomplete, listener: zui.Listener) Autocomplete {
        var copy = self;
        copy.on_activate = listener;
        return copy;
    }

    /// Chrome that looks like a text input (editable text uses zui's
    /// TextField entity; apps compose it inside this frame).
    pub fn render(self: Autocomplete) zui.Element {
        var row = zui.div().flex_row().items_center().gap(8).h(38).px(12)
            .rounded_lg().bg(theme.background)
            .border_1().border_color(theme.input_border)
            .child(support.label(
            if (self.value_text.len > 0) self.value_text else self.placeholder_text,
            14,
            if (self.value_text.len > 0) theme.foreground else theme.muted_foreground,
        ));
        row = row.child(zui.spacer());
        if (self.on_activate) |listener| {
            row = row.cursor_pointer().on_click(listener);
        }
        row = row.child(zui.div().h(18).px(4).rounded(4).bg(theme.secondary)
            .flex_row().items_center()
            .child(support.label("↵", 11, theme.muted_foreground)));
        return row;
    }
};

const std = @import("std");

test "defaults" {
    const ac = Autocomplete.init();
    try std.testing.expectEqualStrings("", ac.value_text);
    try std.testing.expect(ac.on_activate == null);
}
