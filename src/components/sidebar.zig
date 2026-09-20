//! Sidebar — the app-level left navigation (the dashboard's sidebar).
//!
//! Layout shell: brand row at top, nav groups, a spacer, then secondary
//! items and an optional footer element (e.g. an avatar chip).
//!
//! ```zig
//! const groups = [_]Sidebar.Group{
//!     .{ .items = &.{
//!         .{ .label = "Dashboard", .icon = .layout_dashboard, .active = self.page == .dashboard },
//!     } },
//!     .{ .title = "Documents", .items = &.{
//!         .{ .label = "Data Library", .icon = .database },
//!     } },
//! };
//! Sidebar.init(&groups)
//!     .brand(.layout_panel_left, "Acme Inc.")
//!     .secondary(&.{
//!         .{ .label = "Settings", .icon = .settings, .on_click = cx.listener(State, openSettings) },
//!     })
//!     .render(cx)
//! ```
//!
//! Listeners are per item (`Item.on_click`, app-built).

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const default_width: f32 = 288;
pub const brand_height: f32 = 48;
pub const item_height: f32 = 32;
pub const item_padding_x: f32 = 12;
pub const item_gap: f32 = 4;
pub const icon_size: f32 = 16;

pub const Item = struct {
    label: []const u8 = "",
    icon: ?icon_component.Name = null,
    active: bool = false,
    on_click: ?zui.Listener = null,
};

pub const Group = struct {
    title: []const u8 = "",
    items: []const Item = &.{},
};

/// Nav item palette (pure; unit-tested).
pub fn itemStyle(active: bool) struct { background: ?zui.Color, hover: ?zui.Color, foreground: zui.Color, icon: zui.Color } {
    return if (active)
        .{ .background = theme.accent, .hover = null, .foreground = theme.foreground, .icon = theme.foreground }
    else
        .{ .background = null, .hover = theme.accent, .foreground = theme.sidebar_foreground, .icon = theme.sidebar_foreground };
}

pub const Sidebar = struct {
    groups: []const Group,
    brand_icon: ?icon_component.Name = null,
    brand_title: []const u8 = "",
    secondary: []const Item = &.{},
    width_px: f32 = default_width,

    pub fn init(groups: []const Group) Sidebar {
        return .{ .groups = groups };
    }

    pub fn brand(self: Sidebar, icon_name: ?icon_component.Name, title: []const u8) Sidebar {
        var copy = self;
        copy.brand_icon = icon_name;
        copy.brand_title = title;
        return copy;
    }

    /// Bottom-of-list items (settings, help, search...).
    pub fn footer(self: Sidebar, items: []const Item) Sidebar {
        var copy = self;
        copy.secondary = items;
        return copy;
    }

    pub fn width(self: Sidebar, px: f32) Sidebar {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn render(self: Sidebar) zui.Element {
        var side = zui.div().flex_col().w(self.width_px).h_full().p(16).bg(theme.page);

        if (self.brand_title.len > 0 or self.brand_icon != null) {
            var brand_row = zui.div().flex_row().items_center().h(brand_height).px(8).gap(10);
            if (self.brand_icon) |name| {
                brand_row = brand_row.child(icon_component.render(name, 20, theme.foreground));
            }
            brand_row = brand_row.child(support.strong(self.brand_title, 16, theme.foreground));
            side = side.child(brand_row);
        }

        for (self.groups) |group| {
            if (group.title.len > 0) {
                side = side.child(zui.div().p(8).pt(24).pl(12)
                    .child(support.label(group.title, 13, theme.muted_foreground)));
            }
            var list = zui.div().flex_col().gap(item_gap);
            for (group.items) |item| {
                list = list.child(renderItem(item));
            }
            side = side.child(list);
        }

        side = side.child(zui.spacer());

        if (self.secondary.len > 0) {
            var tail = zui.div().flex_col().gap(item_gap);
            for (self.secondary) |item| {
                tail = tail.child(renderItem(item));
            }
            side = side.child(tail);
        }
        return side;
    }
};

fn renderItem(item: Item) zui.Element {
    const style = itemStyle(item.active);
    var row = zui.div().flex_row().items_center().gap(12).h(item_height).px(item_padding_x).rounded_lg();
    if (style.background) |background| row = row.bg(background);
    if (style.hover) |hover| row = row.hover_bg(hover);
    if (item.on_click) |listener| row = row.cursor_pointer().on_click(listener);
    if (item.icon) |name| {
        row = row.child(icon_component.render(name, icon_size, style.icon));
    }
    return row.child(support.label(item.label, 14, style.foreground));
}

const std = @import("std");

test "nav item style follows active" {
    const idle = itemStyle(false);
    try std.testing.expect(idle.background == null);
    try std.testing.expectEqual(theme.accent, idle.hover.?);
    try std.testing.expectEqual(theme.sidebar_foreground, idle.foreground);

    const active = itemStyle(true);
    try std.testing.expectEqual(theme.accent, active.background.?);
    try std.testing.expectEqual(theme.foreground, active.foreground);
}

test "metrics" {
    try std.testing.expectEqual(@as(f32, 288), default_width);
    try std.testing.expectEqual(@as(f32, 32), item_height);
}
