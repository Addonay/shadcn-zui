//! Transfer — Ant/Mantine's two-panel move-list.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const button_component = @import("button.zig");
const list_component = @import("list.zig");

pub const Transfer = struct {
    heading_left: []const u8 = "Source",
    heading_right: []const u8 = "Target",
    left_items: []const list_component.Item,
    right_items: []const list_component.Item,
    on_to_right: ?zui.elements.Listener = null,
    on_to_left: ?zui.elements.Listener = null,

    pub fn init(left_items: []const list_component.Item, right_items: []const list_component.Item) Transfer {
        return .{ .left_items = left_items, .right_items = right_items };
    }

    pub fn onToRight(self: Transfer, listener: zui.elements.Listener) Transfer {
        var copy = self;
        copy.on_to_right = listener;
        return copy;
    }

    pub fn onToLeft(self: Transfer, listener: zui.elements.Listener) Transfer {
        var copy = self;
        copy.on_to_left = listener;
        return copy;
    }

    pub fn render(self: Transfer) zui.Element {
        const left_panel = list_component.List.init(self.left_items)
            .width(220)
            .heading(self.heading_right);
        _ = left_panel;
        const right = list_component.List.init(self.right_items)
            .width(220)
            .heading(self.heading_right);

        var controls = zui.div().flex_col().items_center().gap(8);
        var to_right = button_component.IconButton.init(.chevron_right).variant(.outline).size(32, 16);
        var to_left = button_component.IconButton.init(.chevron_left).variant(.outline).size(32, 16);
        if (self.on_to_right) |listener| to_right = to_right.onClick(listener);
        if (self.on_to_left) |listener| to_left = to_left.onClick(listener);
        controls = controls.child(to_right.render());
        controls = controls.child(to_left.render());

        return zui.div().flex_row().items_center().gap(12)
            .child(list_component.List.init(self.left_items).width(220).heading(self.heading_left))
            .child(controls)
            .child(right);
    }
};

const std = @import("std");

test "defaults" {
    var transfer = Transfer.init(&.{}, &.{});
    try std.testing.expectEqualStrings("Source", transfer.heading_left);
    transfer = transfer.onToRight(undefined);
    try std.testing.expect(transfer.on_to_right != null);
}
