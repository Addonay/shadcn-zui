//! Link — an inline text link.
//!
//! zui has no anchors or text underline yet, so the affordance comes from
//! color plus hover/cursor when a listener is attached.

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const text_size: f32 = 14;

pub fn linkColor() zui.Color {
    return theme.body;
}

pub const Link = struct {
    text: []const u8,
    href_icon: ?icon_component.Name = null,
    listener: ?zui.elements.Listener = null,

    pub fn init(text: []const u8) Link {
        return .{ .text = text };
    }

    /// Optional leading icon (e.g. `.github` for an external link).
    pub fn icon(self: Link, name: icon_component.Name) Link {
        var copy = self;
        copy.href_icon = name;
        return copy;
    }

    pub fn onClick(self: Link, listener: zui.elements.Listener) Link {
        var copy = self;
        copy.listener = listener;
        return copy;
    }

    pub fn render(self: Link) zui.Element {
        var link = zui.div().flex_row().items_center().gap(6);
        if (self.href_icon) |name| {
            link = link.child(icon_component.render(name, 14, theme.muted_foreground));
        }
        link = link.child(support.label(self.text, text_size, linkColor()));
        if (self.listener) |listener| {
            link = link.px(2).rounded(4).cursor_pointer().hover_bg(theme.accent).on_click(listener);
        }
        return link;
    }
};

const std = @import("std");

test "link color is the body token" {
    try std.testing.expectEqual(theme.body, linkColor());
}
