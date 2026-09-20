//! Message — gpui-kit's composed chat message block.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");
const avatar_component = @import("avatar.zig");
const bubble_component = @import("bubble.zig");

pub const Role = enum { user, assistant, system };

pub const Message = struct {
    author: []const u8,
    time_text: ?[]const u8 = null,
    role_kind: Role = .user,
    /// Message body element — frame-local, set during render.
    content_value: zui.Element = undefined,
    /// Avatar name for initials; owned by the caller.
    avatar_name: []const u8 = "",

    pub fn init(author: []const u8) Message {
        return .{ .author = author };
    }

    pub fn at(self: Message, time_text: []const u8) Message {
        var copy = self;
        copy.time_text = time_text;
        return copy;
    }

    pub fn role(self: Message, kind: Role) Message {
        var copy = self;
        copy.role_kind = kind;
        return copy;
    }

    pub fn content(self: Message, element: zui.Element) Message {
        var copy = self;
        copy.content_value = element;
        return copy;
    }

    pub fn avatar(self: Message, name: []const u8) Message {
        var copy = self;
        copy.avatar_name = name;
        return copy;
    }

    pub fn render(self: Message) zui.Element {
        const mine = self.role_kind == .user;
        var head = zui.div().flex_row().items_center().gap(8)
            .child(support.strong(self.author, 13, theme.foreground));
        if (self.time_text) |text| {
            head = head.child(support.label(text, 11, theme.faint));
        }
        const bubble = bubble_component.Bubble.init(zui.div().flex_col().gap(2)
            .child(head)
            .child(self.content_value))
            .alignment(if (mine) .end else .start)
            .isMine(mine)
            .render();
        return zui.div().flex_row().items_start().gap(10).w_full()
            .child(avatar_component.Avatar.init(self.avatar_name).size(.sm).render())
            .child(zui.div().flex_1().child(bubble));
    }
};

const std = @import("std");

test "roles" {
    var message = Message.init("Eddie");
    try std.testing.expect(message.role_kind == .user);
    message = message.role(.assistant);
    try std.testing.expect(message.role_kind == .assistant);
}
