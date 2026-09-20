//! DropdownMenu — shadcn/ui's context menu panel, anchored at a window point.
//!
//! Same overlay mechanics as `popover`: append `render()` as the **last
//! child of the app root**; the panel floats at `at(x, y)` (usually where
//! the triggering click happened — `window.pointerPosition()` in the open
//! callback). Items are caller-built so each carries its own listener.
//!
//! ```zig
//! var items: [3]Item = .{
//!     .{ .label = "Open", .icon = .folder, .on_click = cx.listener(State, open) },
//!     .{ .kind = .separator },
//!     .{ .label = "Delete", .danger = true, .on_click = cx.listener(State, remove) },
//! };
//! if (self.menu_open) page = page.child(
//!     DropdownMenu.init(&items).at(self.menu_x, self.menu_y)
//!         .onScrimClick(cx.listener(State, closeMenu)).render(),
//! );
//! ```

const zui = @import("zui");

const dialog_component = @import("dialog.zig");
const icon_component = @import("icon/root.zig");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Kind = enum { item, separator };

pub const Item = struct {
    kind: Kind = .item,
    label: []const u8 = "",
    icon: ?icon_component.Name = null,
    /// Right-aligned key hint (caller-owned slice), e.g. "⌘K".
    shortcut: ?[]const u8 = null,
    danger: bool = false,
    disabled: bool = false,
    on_click: ?zui.Listener = null,
};

/// shadcn menu width (`w-56` = 224px).
pub const default_width: f32 = 224;
pub const item_height: f32 = 32;
pub const item_gap: f32 = 1;
pub const panel_padding: f32 = 4;
pub const anchor_gap: f32 = 6;

/// Resolved row palette (pure; unit-tested).
pub fn itemStyle(item: Item) struct { foreground: zui.Color, hover: ?zui.Color, icon: zui.Color } {
    const foreground = if (item.danger) theme.destructive else theme.foreground;
    return .{
        .foreground = foreground,
        .hover = if (item.disabled) null else theme.accent,
        .icon = if (item.danger) theme.destructive else theme.muted_foreground,
    };
}

pub const DropdownMenu = struct {
    items: []const Item,
    anchor_x: f32 = 0,
    anchor_y: f32 = 0,
    width_px: f32 = default_width,
    on_scrim_click: ?zui.Listener = null,

    pub fn init(items: []const Item) DropdownMenu {
        return .{ .items = items };
    }

    pub fn at(self: DropdownMenu, x: f32, y: f32) DropdownMenu {
        var copy = self;
        copy.anchor_x = x;
        copy.anchor_y = y;
        return copy;
    }

    pub fn width(self: DropdownMenu, px: f32) DropdownMenu {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    /// Dismiss-on-outside-click (recommended).
    pub fn onScrimClick(self: DropdownMenu, listener: zui.Listener) DropdownMenu {
        var copy = self;
        copy.on_scrim_click = listener;
        return copy;
    }

    /// The full-screen overlay. Append as the last child of the app root.
    pub fn render(self: DropdownMenu) zui.Element {
        var overlay = zui.div().absolute().inset(0);
        if (self.on_scrim_click != null) {
            overlay = overlay.child(dialog_component.scrimLayer(self.on_scrim_click));
        }

        var panel = zui.div().absolute()
            .left(self.anchor_x + anchor_gap)
            .top(self.anchor_y + anchor_gap)
            .w(self.width_px)
            .flex_col().p(panel_padding).gap(item_gap)
            .rounded_lg().bg(theme.popover)
            .border_1().border_color(theme.border)
            .shadow_lg()
            .on_click(support.noopListener());
        for (self.items) |item| {
            panel = panel.child(renderItem(item));
        }

        return overlay.child(panel);
    }
};

fn renderItem(item: Item) zui.Element {
    if (item.kind == .separator) {
        return zui.div().py(3)
            .child(zui.div().h(1).bg(theme.border));
    }

    const style = itemStyle(item);
    var row = zui.div().flex_row().items_center().gap(8)
        .h(item_height).px(8).rounded(6);
    if (style.hover) |hover| row = row.hover_bg(hover);
    if (!item.disabled) {
        row = row.cursor_pointer();
        if (item.on_click) |listener| row = row.on_click(listener);
    } else {
        row = row.opacity(0.5);
    }
    if (item.icon) |name| {
        row = row.child(icon_component.render(name, 16, style.icon));
    }
    row = row.child(support.label(item.label, 13, style.foreground));
    if (item.shortcut) |shortcut| {
        row = row.child(zui.spacer())
            .child(support.label(shortcut, 12, theme.muted_foreground));
    }
    return row;
}

const std = @import("std");

test "item style resolves danger and disabled" {
    const normal = itemStyle(.{ .label = "Open" });
    try std.testing.expectEqual(theme.foreground, normal.foreground);
    try std.testing.expectEqual(theme.accent, normal.hover.?);

    const danger = itemStyle(.{ .label = "Delete", .danger = true });
    try std.testing.expectEqual(theme.destructive, danger.foreground);
    try std.testing.expectEqual(theme.destructive, danger.icon);

    const disabled = itemStyle(.{ .label = "Copy", .disabled = true });
    try std.testing.expect(disabled.hover == null);
}

test "menu metrics follow shadcn" {
    try std.testing.expectEqual(@as(f32, 224), default_width);
    try std.testing.expectEqual(@as(f32, 32), item_height);
}
