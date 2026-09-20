//! Comment — Ant's avatar + content + actions row.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");
const avatar_component = @import("avatar.zig");

pub const Comment = struct {
    author: []const u8,
    /// "3 hours ago" — borrowed until paint.
    time_text: ?[]const u8 = null,
    /// Body element — frame-local, set during render.
    content_value: ?zui.Element = null,
    /// Small action links — frame-local, set during render.
    actions_value: ?zui.Element = null,
    /// Avatar name for initials; owned by the caller.
    avatar_name: []const u8 = "",

    pub fn init(author: []const u8) Comment {
        return .{ .author = author };
    }

    pub fn at(self: Comment, time_text: []const u8) Comment {
        var copy = self;
        copy.time_text = time_text;
        return copy;
    }

    pub fn avatar(self: Comment, name: []const u8) Comment {
        var copy = self;
        copy.avatar_name = name;
        return copy;
    }

    pub fn content(self: Comment, element: zui.Element) Comment {
        var copy = self;
        copy.content_value = element;
        return copy;
    }

    pub fn actions(self: Comment, element: zui.Element) Comment {
        var copy = self;
        copy.actions_value = element;
        return copy;
    }

    pub fn render(self: Comment) zui.Element {
        var head = zui.div().flex_row().items_center().gap(8)
            .child(support.strong(self.author, 14, theme.foreground));
        if (self.time_text) |text| {
            head = head.child(support.label(text, 12, theme.faint));
        }
        var col = zui.div().flex_1().flex_col().gap(4).child(head);
        if (self.content_value) |element| col = col.child(element);
        if (self.actions_value) |element| col = col.child(element);
        var row = zui.div().flex_row().items_center().gap(12)
            .child(avatar_component.Avatar.init(self.avatar_name).size(.sm).render());
        return row.child(col);
    }
};

const std = @import("std");

test "defaults" {
    const comment = Comment.init("Eddie");
    try std.testing.expectEqualStrings("Eddie", comment.author);
    try std.testing.expect(comment.time_text == null);
}
