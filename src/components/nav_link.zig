//! NavLink — Mantine's sidebar-style link row (active state, count, chevron).

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

/// Row background for the active state (pure; unit-tested).
pub fn backgroundFor(active: bool) ?zui.Color {
    return if (active) theme.accent else null;
}

pub const NavLink = struct {
    label_text: []const u8,
    icon_name: ?icon_component.Name = null,
    active: bool = false,
    count_text: ?[]const u8 = null,
    chevron: bool = false,
    on_click: ?zui.elements.Listener = null,

    pub fn init(label_text: []const u8) NavLink {
        return .{ .label_text = label_text };
    }

    pub fn icon(self: NavLink, name: icon_component.Name) NavLink {
        var copy = self;
        copy.icon_name = name;
        return copy;
    }

    pub fn isActive(self: NavLink, value: bool) NavLink {
        var copy = self;
        copy.active = value;
        return copy;
    }

    pub fn count(self: NavLink, text: []const u8) NavLink {
        var copy = self;
        copy.count_text = text;
        return copy;
    }

    pub fn withChevron(self: NavLink) NavLink {
        var copy = self;
        copy.chevron = true;
        return copy;
    }

    pub fn onClick(self: NavLink, listener: zui.elements.Listener) NavLink {
        var copy = self;
        copy.on_click = listener;
        return copy;
    }

    pub fn render(self: NavLink) zui.Element {
        var row = zui.div().flex_row().items_center().gap(10).h(32).px(10)
            .rounded(8);
        if (backgroundFor(self.active)) |color| row = row.bg(color);
        row = row.hover_bg(theme.accent);
        if (self.on_click != null) row = row.cursor_pointer();
        if (self.on_click) |listener| row = row.on_click(listener);
        if (self.icon_name) |name| {
            row = row.child(icon_component.render(name, 16, theme.muted_foreground));
        }
        row = row.child(support.label(self.label_text, 14, if (self.active) theme.foreground else theme.sidebar_foreground));
        row = row.child(zui.spacer());
        if (self.count_text) |text| {
            row = row.child(support.label(text, 12, theme.muted_foreground));
        }
        if (self.chevron) {
            row = row.child(icon_component.render(semantic.chevron_right, 14, theme.faint));
        }
        return row;
    }
};

const std = @import("std");

test "active background" {
    try std.testing.expectEqual(@as(?zui.Color, theme.accent), backgroundFor(true));
    try std.testing.expectEqual(@as(?zui.Color, null), backgroundFor(false));
}
