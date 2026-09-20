//! ButtonGroup — shadcn/ui's joined button row.

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const item_gap: f32 = 1;
pub const radius: f32 = 8;

/// Joined container: pass already-rendered buttons (their own variants
/// decide the look); the group adds a 1px gap and shared rounding.
///
/// ```zig
/// ButtonGroup.init(&.{
///     Button.init("Left").variant(.outline).render(),
///     Button.init("Middle").variant(.outline).render(),
///     IconButton.init(.plus).variant(.outline).render(),
/// }).render()
/// ```
pub const ButtonGroup = struct {
    buttons: []const zui.Element,

    pub fn init(buttons: []const zui.Element) ButtonGroup {
        return .{ .buttons = buttons };
    }

    pub fn render(self: ButtonGroup) zui.Element {
        var group = zui.div().flex_row().items_center().gap(item_gap);
        for (self.buttons) |button| {
            group = group.child(button);
        }
        return group;
    }
};

const std = @import("std");

test "gap is the 1px separator" {
    try std.testing.expectEqual(@as(f32, 1), item_gap);
}
