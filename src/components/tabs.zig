//! Tabs — shadcn/ui's `TabsList` styled after the dashboard's segmented
//! toolbar (dash `table.zig`'s `toolbar` + `tabButton`).
//!
//! The caller builds an inline array of [`Item`]s — including listeners from
//! its own `Context` — and the builder only borrows the slice, so there is no
//! allocation and no owned storage:
//!
//! ```zig
//! Tabs.init(&.{
//!     .{ .label = "Outline", .active = true, .on_click = cx.listener(State, outline) },
//!     .{ .label = "Past Performance", .count = "3", .on_click = cx.listenerWith(u8, State, tab, 1) },
//! }).render()
//! ```
//!
//! Dashboard token mapping: `table_head` -> `theme.secondary`,
//! `tab_active` -> `theme.accent`, `hover` -> `theme.accent_hover`.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");

/// List container metrics (dash `table.zig` `toolbar`).
pub const LIST_PADDING: f32 = 2;
pub const LIST_GAP: f32 = 2;

/// Trigger metrics (dash `table.zig` `tabButton`).
pub const TRIGGER_HEIGHT: f32 = 32;
pub const TRIGGER_PADDING_X: f32 = 12;
pub const TRIGGER_GAP: f32 = 6;
pub const TRIGGER_ICON_SIZE: f32 = 16;
pub const TRIGGER_LABEL_SIZE: f32 = 14;

/// Count pill metrics (dash `table.zig` `tabButton`).
pub const COUNT_HEIGHT: f32 = 18;
pub const COUNT_PADDING_X: f32 = 5;
pub const COUNT_LABEL_SIZE: f32 = 11;

/// One trigger in the list. `on_click` is built by the app (`cx.listener...`).
pub const Item = struct {
    label: []const u8,
    active: bool = false,
    count: ?[]const u8 = null,
    icon: ?icon_component.Name = null,
    on_click: ?zui.Listener = null,
};

/// Resolved trigger colors; kept separate from rendering so it stays testable
/// without a render frame.
pub const TriggerStyle = struct {
    background: ?zui.Color,
    hover: ?zui.Color,
    foreground: zui.Color,
};

/// Active triggers get the accent surface; inactive ones only change surface
/// on hover. Text uses `foreground` when active, `muted_foreground` otherwise.
pub fn itemStyle(active: bool) TriggerStyle {
    if (active) {
        return .{ .background = theme.accent, .hover = null, .foreground = theme.foreground };
    }
    return .{ .background = null, .hover = theme.accent_hover, .foreground = theme.muted_foreground };
}

/// The list surface, defaulting to the dashboard's `table_head` token.
pub fn listBackground(override: ?zui.Color) zui.Color {
    return override orelse theme.secondary;
}

pub const Tabs = struct {
    items: []const Item,
    background: ?zui.Color = null,

    pub fn init(items: []const Item) Tabs {
        return .{ .items = items };
    }

    /// Override the list surface; defaults to `theme.secondary`.
    pub fn bg(self: Tabs, value: zui.Color) Tabs {
        var copy = self;
        copy.background = value;
        return copy;
    }

    pub fn render(self: Tabs) zui.Element {
        var list = zui.div().flex_row().items_center()
            .p(LIST_PADDING).gap(LIST_GAP).rounded_lg()
            .bg(listBackground(self.background));
        for (self.items) |item| {
            list = list.child(renderItem(item));
        }
        return list;
    }
};

/// Render a single trigger. Public so callers can compose lists themselves.
pub fn renderItem(item: Item) zui.Element {
    const colors = itemStyle(item.active);
    var trigger = zui.div().flex_row().items_center().gap(TRIGGER_GAP)
        .h(TRIGGER_HEIGHT).px(TRIGGER_PADDING_X).rounded_lg();
    if (colors.background) |background| trigger = trigger.bg(background);
    if (colors.hover) |hover| trigger = trigger.hover_bg(hover);
    if (item.on_click) |listener| {
        trigger = trigger.cursor_pointer().on_click(listener);
    }
    if (item.icon) |name| {
        trigger = trigger.child(icon_component.render(name, TRIGGER_ICON_SIZE, colors.foreground));
    }
    trigger = trigger.child(support.label(item.label, TRIGGER_LABEL_SIZE, colors.foreground));
    if (item.count) |count| {
        trigger = trigger.child(zui.div().flex_row().items_center().justify_center()
            .h(COUNT_HEIGHT).px(COUNT_PADDING_X).rounded_full()
            .bg(theme.border_strong)
            .child(support.label(count, COUNT_LABEL_SIZE, theme.foreground)));
    }
    return trigger;
}

const std = @import("std");

test "active trigger uses the accent surface" {
    const active = itemStyle(true);
    try std.testing.expectEqual(theme.accent, active.background.?);
    try std.testing.expect(active.hover == null);
    try std.testing.expectEqual(theme.foreground, active.foreground);
}

test "inactive trigger hovers with accent_hover" {
    const inactive = itemStyle(false);
    try std.testing.expect(inactive.background == null);
    try std.testing.expectEqual(theme.accent_hover, inactive.hover.?);
    try std.testing.expectEqual(theme.muted_foreground, inactive.foreground);
}

test "list falls back to the secondary surface" {
    try std.testing.expectEqual(theme.secondary, listBackground(null));
    try std.testing.expectEqual(theme.card, listBackground(theme.card));
}

test "trigger and list metrics match the dashboard toolbar" {
    try std.testing.expectEqual(@as(f32, 2), LIST_PADDING);
    try std.testing.expectEqual(@as(f32, 2), LIST_GAP);
    try std.testing.expectEqual(@as(f32, 32), TRIGGER_HEIGHT);
    try std.testing.expectEqual(@as(f32, 12), TRIGGER_PADDING_X);
    try std.testing.expectEqual(@as(f32, 6), TRIGGER_GAP);
    try std.testing.expectEqual(@as(f32, 16), TRIGGER_ICON_SIZE);
    try std.testing.expectEqual(@as(f32, 14), TRIGGER_LABEL_SIZE);
    try std.testing.expectEqual(@as(f32, 18), COUNT_HEIGHT);
    try std.testing.expectEqual(@as(f32, 5), COUNT_PADDING_X);
    try std.testing.expectEqual(@as(f32, 11), COUNT_LABEL_SIZE);
}

test "items default to inactive and undecorated" {
    const item = Item{ .label = "Outline" };
    try std.testing.expect(!item.active);
    try std.testing.expect(item.count == null);
    try std.testing.expect(item.icon == null);
    try std.testing.expect(item.on_click == null);
}
