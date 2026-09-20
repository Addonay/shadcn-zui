//! Indicator — Mantine/MUI's dot/count badge layered over any content.
//! (Ant's Badge, MUI's Badge, HeroUI's Chip indicator.)

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const dot_size: f32 = 8;
pub const count_height: f32 = 16;

pub const Corner = enum { top_left, top_right, bottom_left, bottom_right };

pub const Indicator = struct {
    child_element: zui.Element,
    /// Bare dot instead of a count.
    dot: bool = false,
    count_text: []const u8 = "",
    corner_kind: Corner = .top_right,
    hide_when_zero: bool = false,
    /// Numeric value the caller formatted into its own buffer.
    count_value: usize = 0,

    pub fn init(child: zui.Element) Indicator {
        return .{ .child_element = child };
    }

    pub fn asDot(self: Indicator) Indicator {
        var copy = self;
        copy.dot = true;
        return copy;
    }

    pub fn count(self: Indicator, text: []const u8, value: usize) Indicator {
        var copy = self;
        copy.count_text = text;
        copy.count_value = value;
        return copy;
    }

    pub fn corner(self: Indicator, kind: Corner) Indicator {
        var copy = self;
        copy.corner_kind = kind;
        return copy;
    }

    /// Hides the badge when the numeric value is zero.
    pub fn hideZero(self: Indicator) Indicator {
        var copy = self;
        copy.hide_when_zero = true;
        return copy;
    }

    fn badge(self: Indicator) zui.Element {
        if (self.dot) {
            return zui.div().size(dot_size).rounded_full().bg(theme.destructive);
        }
        return zui.div().h(count_height).px(4).rounded_full().bg(theme.destructive)
            .flex_row().items_center().justify_center()
            .child(support.label(self.count_text, 10, theme.destructive_foreground));
    }

    pub fn render(self: Indicator) zui.Element {
        if (self.hide_when_zero and self.count_value == 0 and !self.dot) {
            return self.child_element;
        }
        const overlay = self.badge();
        var anchor = zui.div().absolute();
        switch (self.corner_kind) {
            .top_left => anchor = anchor.top(-3).left(-3),
            .top_right => anchor = anchor.top(-3).right(-3),
            .bottom_left, .bottom_right => anchor = anchor.top(-3).right(-3),
        }
        return zui.div().flex_col()
            .child(self.child_element)
            .child(anchor.child(overlay));
    }
};

const std = @import("std");

test "badge metrics" {
    try std.testing.expectEqual(@as(f32, 8), dot_size);
    try std.testing.expectEqual(@as(f32, 16), count_height);
}
