//! Item — shadcn/ui's media/content/actions row scaffolding.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Item = struct {
    title: []const u8,
    description_text: ?[]const u8 = null,
    /// Leading media element (icon or avatar) — frame-local, set during render.
    media_value: ?zui.Element = null,
    /// Trailing actions element — frame-local, set during render.
    actions_value: ?zui.Element = null,

    pub fn init(title: []const u8) Item {
        return .{ .title = title };
    }

    pub fn description(self: Item, text: []const u8) Item {
        var copy = self;
        copy.description_text = text;
        return copy;
    }

    pub fn media(self: Item, element: zui.Element) Item {
        var copy = self;
        copy.media_value = element;
        return copy;
    }

    pub fn actions(self: Item, element: zui.Element) Item {
        var copy = self;
        copy.actions_value = element;
        return copy;
    }

    pub fn render(self: Item) zui.Element {
        var row = zui.div().flex_row().items_center().gap(12)
            .p(12).rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border);
        if (self.media_value) |element| row = row.child(element);
        var text = zui.div().flex_1().flex_col().gap(2)
            .child(support.strong(self.title, 14, theme.foreground));
        if (self.description_text) |value| {
            text = text.child(support.label(value, 13, theme.muted_foreground));
        }
        row = row.child(text);
        if (self.actions_value) |element| row = row.child(element);
        return row;
    }
};

const std = @import("std");
