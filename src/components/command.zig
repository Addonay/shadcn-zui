//! Command — shadcn/ui's command palette list (input + filtered rows).
//!
//! Presentational: the app owns the query and filtering, and usually hosts
//! the panel inside a `Popover` overlay at the root.
//!
//! ```zig
//! var items: [4]Command.Item = .{
//!     .{ .label = "New Project", .icon = .plus, .shortcut = "⌘N", .selected = self.hovered == 0, .on_click = ... },
//!     .{ .kind = .separator },
//!     ...
//! };
//! Popover.init(x, y).width(330)
//!     .content(Command.init(&items).query(self.query).render())
//!     .onScrimClick(cx.listener(State, closePalette))
//!     .render()
//! ```

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Kind = enum { item, separator };

pub const Item = struct {
    kind: Kind = .item,
    label: []const u8 = "",
    icon: ?icon_component.Name = null,
    /// Right-aligned key hint (caller-owned slice).
    shortcut: ?[]const u8 = null,
    /// Highlighted (arrow-key selection in the app).
    selected: bool = false,
    on_click: ?zui.elements.Listener = null,
};

pub const default_width: f32 = 330;
pub const row_height: f32 = 32;
pub const panel_padding: f32 = 8;

pub fn rowStyle(selected: bool) struct { background: ?zui.Color, hover: ?zui.Color, foreground: zui.Color } {
    return if (selected)
        .{ .background = theme.accent, .hover = null, .foreground = theme.foreground }
    else
        .{ .background = null, .hover = theme.accent, .foreground = theme.muted_foreground };
}

pub const Command = struct {
    items: []const Item,
    /// The current query, shown in the input chrome (caller-owned slice).
    query_value: ?[]const u8 = null,
    placeholder_text: []const u8 = "Type a command or search...",
    width_px: f32 = default_width,
    empty_text: []const u8 = "No results.",

    pub fn init(items: []const Item) Command {
        return .{ .items = items };
    }

    pub fn query(self: Command, text: ?[]const u8) Command {
        var copy = self;
        copy.query_value = text;
        return copy;
    }

    pub fn placeholder(self: Command, text: []const u8) Command {
        var copy = self;
        copy.placeholder_text = text;
        return copy;
    }

    pub fn width(self: Command, px: f32) Command {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn empty(self: Command, text: []const u8) Command {
        var copy = self;
        copy.empty_text = text;
        return copy;
    }

    pub fn render(self: Command) zui.Element {
        var panel = zui.div().w(self.width_px).flex_col().p(panel_padding).gap(2)
            .rounded_lg().bg(theme.popover)
            .border_1().border_color(theme.border)
            .shadow_lg();

        // Input chrome: search icon + caller-owned query/placeholder text.
        panel = panel.child(zui.div().flex_row().items_center().gap(8).h(36).px(10)
            .border_b_1().border_color(theme.border)
            .child(icon_component.render(semantic.search, 16, theme.muted_foreground))
            .child(support.label(self.query_value orelse self.placeholder_text, 14, if (self.query_value != null) theme.foreground else theme.muted_foreground)));

        var rows = zui.div().flex_col().gap(1).pt(4);
        var count: usize = 0;
        for (self.items) |item| {
            if (item.kind == .separator) {
                rows = rows.child(zui.div().h(1).bg(theme.border));
                continue;
            }
            rows = rows.child(renderRow(item));
            count += 1;
        }
        if (count == 0) {
            rows = rows.child(zui.div().flex_row().items_center().justify_center().h(row_height)
                .child(support.label(self.empty_text, 13, theme.muted_foreground)));
        }
        return panel.child(rows);
    }
};

fn renderRow(item: Item) zui.Element {
    const style = rowStyle(item.selected);
    var row = zui.div().flex_row().items_center().gap(8).h(row_height).px(8).rounded(4);
    if (style.background) |background| row = row.bg(background);
    if (style.hover) |hover| row = row.hover_bg(hover);
    if (item.on_click) |listener| row = row.cursor_pointer().on_click(listener);
    if (item.icon) |name| {
        row = row.child(icon_component.render(name, 16, theme.muted_foreground));
    }
    row = row.child(support.label(item.label, 13, style.foreground));
    if (item.shortcut) |shortcut| {
        row = row.child(zui.spacer()).child(support.label(shortcut, 12, theme.muted_foreground));
    }
    return row;
}

const std = @import("std");

test "row style follows selection" {
    const plain = rowStyle(false);
    try std.testing.expect(plain.background == null);
    try std.testing.expectEqual(theme.accent, plain.hover.?);

    const selected = rowStyle(true);
    try std.testing.expectEqual(theme.accent, selected.background.?);
    try std.testing.expect(selected.hover == null);
}

test "panel metrics" {
    try std.testing.expectEqual(@as(f32, 330), default_width);
    try std.testing.expectEqual(@as(f32, 32), row_height);
}
