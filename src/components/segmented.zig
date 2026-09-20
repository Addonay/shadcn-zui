//! Segmented — Ant/Mantine's segmented control (track + thumb variant of
//! ToggleGroup).

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");

pub const item_height: f32 = 30;
pub const item_padding_x: f32 = 14;

pub const Option = struct {
    label: []const u8,
    selected: bool = false,
    on_click: ?zui.Listener = null,
};

pub const Segmented = struct {
    options: []const Option,

    pub fn init(options: []const Option) Segmented {
        return .{ .options = options };
    }

    pub fn render(self: Segmented) zui.Element {
        var track = zui.div().flex_row().items_center().gap(2).p(2)
            .rounded_lg().bg(theme.secondary);
        for (self.options) |option| {
            var slot = zui.div().flex_row().items_center().justify_center()
                .h(item_height).px(item_padding_x).rounded(8);
            if (option.selected) {
                slot = slot.bg(theme.primary).shadow_lg();
            } else {
                slot = slot.hover_bg(theme.accent);
            }
            if (option.on_click != null) slot = slot.cursor_pointer();
            if (option.on_click) |listener| slot = slot.on_click(listener);
            slot = slot.child(support.label(option.label, 13, if (option.selected) theme.primary_foreground else theme.muted_foreground));
            track = track.child(slot);
        }
        return track;
    }
};

const std = @import("std");

test "metrics" {
    try std.testing.expectEqual(@as(f32, 14), item_padding_x);
}
