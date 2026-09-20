//! Affix — Mantine/Ant's fixed-position corner button (BackTop).

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const Position = enum { bottom_right, bottom_left, top_right, top_left };

pub const Affix = struct {
    child_element: zui.Element,
    position_kind: Position = .bottom_right,
    offset_px: f32 = 24,

    pub fn init(child: zui.Element) Affix {
        return .{ .child_element = child };
    }

    pub fn position(self: Affix, kind: Position) Affix {
        var copy = self;
        copy.position_kind = kind;
        return copy;
    }

    pub fn offset(self: Affix, px: f32) Affix {
        var copy = self;
        copy.offset_px = px;
        return copy;
    }

    pub fn render(self: Affix) zui.Element {
        var anchor = zui.div().absolute();
        switch (self.position_kind) {
            .bottom_right => anchor = anchor.bottom(self.offset_px).right(self.offset_px),
            .bottom_left => anchor = anchor.bottom(self.offset_px).left(self.offset_px),
            .top_right => anchor = anchor.top(self.offset_px).right(self.offset_px),
            .top_left => anchor = anchor.top(self.offset_px).left(self.offset_px),
        }
        return anchor.child(self.child_element);
    }
};

const std = @import("std");

test "offset default" {
    const affix = Affix{ .child_element = undefined };
    try std.testing.expectEqual(@as(f32, 24), affix.offset_px);
    try std.testing.expectEqual(Position.top_left, (Affix{ .child_element = undefined }).position(.top_left).position_kind);
}
