//! Bubble — gpui-kit/shadcn's chat message surface.

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const Align = enum { start, end };

pub const Bubble = struct {
    /// The message body — frame-local, set during render.
    content_value: zui.Element,
    align_kind: Align = .start,
    mine: bool = false,

    pub fn init(content: zui.Element) Bubble {
        return .{ .content_value = content };
    }

    pub fn alignment(self: Bubble, kind: Align) Bubble {
        var copy = self;
        copy.align_kind = kind;
        return copy;
    }

    /// Own messages use the accent surface.
    pub fn isMine(self: Bubble, value: bool) Bubble {
        var copy = self;
        copy.mine = value;
        return copy;
    }

    pub fn render(self: Bubble) zui.Element {
        const radius: f32 = 12;
        const bubble = zui.div().flex_col().gap(2).px(12).py(8)
            .rounded(radius).bg(if (self.mine) theme.primary else theme.card)
            .border_1().border_color(theme.border)
            .child(self.content_value);
        if (self.align_kind == .end) {
            return zui.div().flex_row().justify_between().w_full()
                .child(zui.spacer()).child(zui.div().max_w_full().child(bubble));
        }
        return zui.div().flex_row().w_full().child(zui.div().max_w_full().child(bubble));
    }
};

const std = @import("std");

test "align default" {
    const bubble = Bubble{ .content_value = undefined };
    try std.testing.expectEqual(Align.start, bubble.align_kind);
    try std.testing.expect(!bubble.mine);
}
