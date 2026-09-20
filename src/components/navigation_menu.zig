//! NavigationMenu — shadcn's horizontal nav list with active pills.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");

pub const item_height: f32 = 34;

pub const Link = struct {
    label: []const u8,
    active: bool = false,
    count_text: ?[]const u8 = null,
    on_click: ?zui.elements.Listener = null,
};

pub const NavigationMenu = struct {
    links: []const Link,

    pub fn init(links: []const Link) NavigationMenu {
        return .{ .links = links };
    }

    pub fn render(self: NavigationMenu) zui.Element {
        var row = zui.div().flex_row().items_center().gap(2).p(4)
            .rounded_lg().bg(theme.card)
            .border_1().border_color(theme.border);
        for (self.links) |link| {
            var slot = zui.div().flex_row().items_center().gap(6).h(item_height).px(12)
                .rounded(8).hover_bg(theme.accent);
            if (link.active) slot = slot.bg(theme.accent);
            if (link.on_click != null) slot = slot.cursor_pointer();
            if (link.on_click) |listener| slot = slot.on_click(listener);
            slot = slot.child(support.label(link.label, 14, if (link.active) theme.foreground else theme.body));
            if (link.count_text) |text| {
                slot = slot.child(zui.div().px(6).rounded_full().bg(theme.secondary)
                    .child(support.label(text, 11, theme.muted_foreground)));
            }
            row = row.child(slot);
        }
        return row;
    }
};

const std = @import("std");

test "metrics" {
    try std.testing.expectEqual(@as(f32, 34), item_height);
}
