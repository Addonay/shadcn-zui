//! FAB — MUI's floating action button: a round accent icon button.

const zui = @import("zui");

const theme = @import("../theme.zig");
const icon_component = @import("icon/root.zig");

pub const size_px: f32 = 56;

pub const Fab = struct {
    icon_name: icon_component.Name,
    on_click: ?zui.elements.Listener = null,
    size_value: f32 = size_px,

    pub fn init(icon_name: icon_component.Name) Fab {
        return .{ .icon_name = icon_name };
    }

    pub fn onClick(self: Fab, listener: zui.elements.Listener) Fab {
        var copy = self;
        copy.on_click = listener;
        return copy;
    }

    pub fn size(self: Fab, px: f32) Fab {
        var copy = self;
        copy.size_value = px;
        return copy;
    }

    pub fn render(self: Fab) zui.Element {
        var button = zui.div().size(self.size_value).flex_row().items_center().justify_center()
            .rounded_full().bg(theme.primary)
            .shadow_lg().hover_bg(theme.primary_hover)
            .child(icon_component.render(self.icon_name, 22, theme.primary_foreground));
        if (self.on_click != null) button = button.cursor_pointer();
        if (self.on_click) |listener| button = button.on_click(listener);
        return button;
    }
};

const std = @import("std");

test "fab size" {
    const fab = Fab{ .icon_name = .plus };
    try std.testing.expectEqual(@as(f32, 56), fab.size_value);
    try std.testing.expectEqual(@as(f32, 56), size_px);
}
