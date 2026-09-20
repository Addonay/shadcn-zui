//! ToggleGroup — shadcn/ui's joined toggles. Controlled.

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const item_height: f32 = 30;
pub const item_padding_x: f32 = 10;
pub const item_radius: f32 = 6;
pub const item_gap: f32 = 1;
pub const list_padding: f32 = 1;
pub const icon_size: f32 = 14;

pub const Item = struct {
    label: []const u8 = "",
    pressed: bool = false,
    icon: ?icon_component.Name = null,
    disabled: bool = false,
    on_click: ?zui.Listener = null,
};

pub const ItemStyle = struct {
    background: ?zui.Color,
    foreground: zui.Color,
    hover: ?zui.Color,
};

/// Pressed items sit on the page surface inside the muted group shell
/// (pure; unit-tested).
pub fn itemStyle(pressed: bool) ItemStyle {
    return if (pressed)
        .{ .background = theme.background, .foreground = theme.foreground, .hover = null }
    else
        .{ .background = null, .foreground = theme.muted_foreground, .hover = theme.accent };
}

pub const ToggleGroup = struct {
    items: []const Item,

    pub fn init(items: []const Item) ToggleGroup {
        return .{ .items = items };
    }

    pub fn render(self: ToggleGroup) zui.Element {
        var list = zui.div().flex_row().items_center().p(list_padding).gap(item_gap)
            .rounded(item_radius + list_padding).bg(theme.muted);
        for (self.items) |item| {
            list = list.child(renderItem(item));
        }
        return list;
    }
};

fn renderItem(item: Item) zui.Element {
    const style = itemStyle(item.pressed);
    var element = zui.div().flex_row().items_center().justify_center().gap(6)
        .h(item_height).px(item_padding_x).rounded(item_radius);
    if (style.background) |background| element = element.bg(background);
    if (style.hover) |hover| element = element.hover_bg(hover);
    if (!item.disabled) {
        element = element.cursor_pointer();
        if (item.on_click) |listener| element = element.on_click(listener);
    } else {
        element = element.opacity(0.5);
    }
    if (item.icon) |name| {
        element = element.child(icon_component.render(name, icon_size, style.foreground));
    }
    if (item.label.len > 0) {
        element = element.child(support.label(item.label, 13, style.foreground));
    }
    return element;
}

const std = @import("std");

test "item style per pressed state" {
    const unpressed = itemStyle(false);
    try std.testing.expect(unpressed.background == null);
    try std.testing.expectEqual(theme.accent, unpressed.hover.?);

    const pressed = itemStyle(true);
    try std.testing.expectEqual(theme.background, pressed.background.?);
    try std.testing.expect(pressed.hover == null);
}
