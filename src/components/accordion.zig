//! Accordion — shadcn/ui's expandable sections. Controlled.

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const row_height: f32 = 48;
pub const row_padding_x: f32 = 16;
pub const content_padding_x: f32 = 16;
pub const content_padding_bottom: f32 = 16;

pub const Item = struct {
    title: []const u8 = "",
    content_value: ?zui.Element = null,
    open: bool = false,
    disabled: bool = false,
    /// Toggle listener (built by the app, one per row).
    on_click: ?zui.elements.Listener = null,
};

/// Which chevron a row shows (zui has no rotation transform, so the glyph
/// swaps instead of rotating 180°).
pub fn chevronFor(open: bool) icon_component.Name {
    return if (open) semantic.chevron_down else semantic.chevron_right;
}

pub const Accordion = struct {
    items: []const Item,

    pub fn init(items: []const Item) Accordion {
        return .{ .items = items };
    }

    pub fn render(self: Accordion) zui.Element {
        var list = zui.div().flex_col().w_full().rounded_lg()
            .border_1().border_color(theme.border);
        for (self.items, 0..) |item, index| {
            const is_last = index == self.items.len - 1;
            var row = zui.div().flex_row().items_center().h(row_height).px(row_padding_x);
            if (!is_last) row = row.border_b_1().border_color(theme.border);
            if (!item.disabled) {
                row = row.cursor_pointer().hover_bg(theme.accent);
                if (item.on_click) |listener| row = row.on_click(listener);
            } else {
                row = row.opacity(0.5);
            }
            row = row.child(support.strong(item.title, 14, theme.foreground))
                .child(zui.spacer())
                .child(icon_component.render(chevronFor(item.open), 16, theme.muted_foreground));
            list = list.child(row);

            if (item.open) {
                if (item.content_value) |content| {
                    var content_block = zui.div().px(content_padding_x);
                    if (!is_last) content_block = content_block.pb(content_padding_bottom);
                    list = list.child(content_block.child(content));
                }
            }
        }
        return list;
    }
};

const std = @import("std");

test "chevron swaps with open state" {
    try std.testing.expectEqual(semantic.chevron_right, chevronFor(false));
    try std.testing.expectEqual(semantic.chevron_down, chevronFor(true));
}

test "row metrics" {
    try std.testing.expectEqual(@as(f32, 48), row_height);
    try std.testing.expectEqual(@as(f32, 16), content_padding_bottom);
}
