//! SearchField — HeroUI's search input chrome with clear + kbd hint.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

pub const SearchField = struct {
    /// Query text; borrowed until paint.
    value_text: []const u8 = "",
    placeholder_text: []const u8 = "Search…",
    kbd_hint: ?[]const u8 = null,
    on_clear: ?zui.Listener = null,

    pub fn init() SearchField {
        return .{};
    }

    pub fn value(self: SearchField, text: []const u8) SearchField {
        var copy = self;
        copy.value_text = text;
        return copy;
    }

    pub fn placeholder(self: SearchField, text: []const u8) SearchField {
        var copy = self;
        copy.placeholder_text = text;
        return copy;
    }

    pub fn hint(self: SearchField, text: []const u8) SearchField {
        var copy = self;
        copy.kbd_hint = text;
        return copy;
    }

    pub fn onClear(self: SearchField, listener: zui.Listener) SearchField {
        var copy = self;
        copy.on_clear = listener;
        return copy;
    }

    pub fn render(self: SearchField) zui.Element {
        var row = zui.div().flex_row().items_center().gap(8).h(38).px(12)
            .rounded_lg().bg(theme.background)
            .border_1().border_color(theme.input_border)
            .child(icon_component.render(semantic.search, 16, theme.muted_foreground))
            .child(support.label(
                if (self.value_text.len > 0) self.value_text else self.placeholder_text,
                14,
                if (self.value_text.len > 0) theme.foreground else theme.muted_foreground,
            ))
            .child(zui.spacer());
        if (self.value_text.len > 0) {
            if (self.on_clear) |listener| {
                row = row.child(zui.div().size(20).flex_row().items_center().justify_center()
                    .rounded(4).cursor_pointer().hover_bg(theme.accent)
                    .on_click(listener)
                    .child(icon_component.render(semantic.close, 12, theme.muted_foreground)));
            }
        } else if (self.kbd_hint) |text| {
            row = row.child(zui.div().h(20).px(6).rounded(4).bg(theme.secondary)
                .flex_row().items_center()
                .child(support.label(text, 11, theme.muted_foreground)));
        }
        return row;
    }
};

const std = @import("std");

test "defaults" {
    const field = SearchField.init();
    try std.testing.expectEqualStrings("Search…", field.placeholder_text);
    try std.testing.expect(field.on_clear == null);
}
