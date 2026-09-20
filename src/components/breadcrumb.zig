//! Breadcrumb — shadcn/ui's trail of links.

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const height: f32 = 24;
pub const item_gap: f32 = 8;

pub const Item = struct {
    label: []const u8 = "",
    /// Optional leading icon (e.g. `.home` on the first crumb).
    icon: ?icon_component.Name = null,
    /// The current page: not clickable, foreground text.
    current: bool = false,
    on_click: ?zui.Listener = null,
};

pub fn separatorColor() zui.Color {
    return theme.faint;
}

pub const Breadcrumb = struct {
    items: []const Item,

    pub fn init(items: []const Item) Breadcrumb {
        return .{ .items = items };
    }

    pub fn render(self: Breadcrumb) zui.Element {
        var row = zui.div().flex_row().items_center().gap(item_gap);
        for (self.items, 0..) |item, index| {
            if (index > 0) {
                row = row.child(icon_component.render(semantic.chevron_right, 14, separatorColor()));
            }
            row = row.child(renderItem(item));
        }
        return row;
    }
};

fn renderItem(item: Item) zui.Element {
    const color = if (item.current) theme.foreground else theme.muted_foreground;
    var crumb = zui.div().flex_row().items_center().gap(6);
    if (item.icon) |name| {
        crumb = crumb.child(icon_component.render(name, 14, color));
    }
    crumb = crumb.child(support.label(item.label, 14, color));
    if (!item.current) {
        crumb = crumb.cursor_pointer();
        if (item.on_click) |listener| crumb = crumb.on_click(listener);
    }
    return crumb;
}

const std = @import("std");

test "separator color" {
    try std.testing.expectEqual(theme.faint, separatorColor());
}

test "metrics" {
    try std.testing.expectEqual(@as(f32, 8), item_gap);
}
