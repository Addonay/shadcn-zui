//! Separator — shadcn/ui's one-pixel divider.
//!
//! Mirrors shadcn's [`Separator`](https://ui.shadcn.com/docs/components/separator):
//! a horizontal rule that fills its container, or a short vertical rule used
//! between inline items.
//!
//! ```zig
//! Separator.init().orientation(.horizontal).color(theme.border).render()
//! Separator.init().orientation(.vertical).length(24).thickness(1).render()
//! ```

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const Orientation = enum { horizontal, vertical };

pub const Metrics = struct {
    /// `null` means `w_full()` (a horizontal separator stretches to its parent).
    width: ?f32,
    /// Horizontal separators are `thickness` tall; vertical ones use `length`
    /// when given, otherwise the 16px inline default.
    height: f32,
};

/// Pure geometry for a separator. `length` only applies to vertical rules.
pub fn metrics(orientation: Orientation, length: ?f32, thickness: f32) Metrics {
    return switch (orientation) {
        .horizontal => .{ .width = null, .height = thickness },
        .vertical => .{ .width = thickness, .height = length orelse 16 },
    };
}

pub const Separator = struct {
    orientation_value: Orientation = .horizontal,
    color_value: zui.Color = theme.border,
    length_value: ?f32 = null,
    thickness_value: f32 = 1,

    pub fn init() Separator {
        return .{};
    }

    pub fn orientation(self: Separator, value: Orientation) Separator {
        var copy = self;
        copy.orientation_value = value;
        return copy;
    }

    pub fn color(self: Separator, value: zui.Color) Separator {
        var copy = self;
        copy.color_value = value;
        return copy;
    }

    pub fn length(self: Separator, px: f32) Separator {
        var copy = self;
        copy.length_value = px;
        return copy;
    }

    pub fn thickness(self: Separator, px: f32) Separator {
        var copy = self;
        copy.thickness_value = px;
        return copy;
    }

    pub fn render(self: Separator) zui.Element {
        const m = metrics(self.orientation_value, self.length_value, self.thickness_value);
        const separator = if (m.width) |value| zui.div().w(value) else zui.div().w_full();
        return separator.h(m.height).bg(self.color_value);
    }
};

const std = @import("std");

test "horizontal separators fill the width at the line thickness" {
    const default = metrics(.horizontal, null, 1);
    try std.testing.expect(default.width == null);
    try std.testing.expectEqual(@as(f32, 1), default.height);

    const thick = metrics(.horizontal, null, 2);
    try std.testing.expect(thick.width == null);
    try std.testing.expectEqual(@as(f32, 2), thick.height);
    // `length` is ignored horizontally.
    try std.testing.expectEqual(@as(f32, 1), metrics(.horizontal, 40, 1).height);
}

test "vertical separators default to a 16px inline rule" {
    const default = metrics(.vertical, null, 1);
    try std.testing.expectEqual(@as(f32, 1), default.width.?);
    try std.testing.expectEqual(@as(f32, 16), default.height);

    const sized = metrics(.vertical, 40, 2);
    try std.testing.expectEqual(@as(f32, 2), sized.width.?);
    try std.testing.expectEqual(@as(f32, 40), sized.height);
}
