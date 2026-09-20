//! InputGroup — shadcn/HeroUI's input with leading/trailing addon elements.

const zui = @import("zui");

const theme = @import("../theme.zig");
const input_component = @import("input.zig");

pub const InputGroup = struct {
    input: input_component.Input,
    /// Addon elements — frame-local, set during render.
    leading_value: ?zui.Element = null,
    trailing_value: ?zui.Element = null,

    pub fn init(input: input_component.Input) InputGroup {
        return .{ .input = input };
    }

    pub fn leading(self: InputGroup, element: zui.Element) InputGroup {
        var copy = self;
        copy.leading_value = element;
        return copy;
    }

    pub fn trailing(self: InputGroup, element: zui.Element) InputGroup {
        var copy = self;
        copy.trailing_value = element;
        return copy;
    }

    pub fn render(self: InputGroup) zui.Element {
        var group = zui.div().flex_row().items_center().gap(8).w(320);
        if (self.leading_value) |element| group = group.child(element);
        group = group.child(self.input.render());
        if (self.trailing_value) |element| group = group.child(element);
        return group;
    }
};

const std = @import("std");

test "defaults" {
    var group = InputGroup{ .input = undefined };
    try std.testing.expect(group.leading_value == null);
    try std.testing.expect(group.trailing_value == null);
    group = group.leading(undefined);
    try std.testing.expect(group.leading_value != null);
}
