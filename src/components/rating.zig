//! Rating — a star rating (gpui-kit's `rating`).
//!
//! Controlled: the app owns the value and builds one listener per star
//! with `cx.listenerWith(usize, App, setRating, i)` (star indices are
//! 1-based), then passes the slice through `onStars`.

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const theme = @import("../theme.zig");

pub const default_max: usize = 5;
pub const default_size: f32 = 20;

/// Star `index_1based` is filled when `value >= index`.
pub fn starState(value: f32, index_1based: usize) bool {
    const index: f32 = @floatFromInt(index_1based);
    return value >= index;
}

pub fn filledColor() zui.Color {
    return theme.warning;
}

pub fn emptyColor() zui.Color {
    return theme.border_strong;
}

pub const Rating = struct {
    value: f32 = 0,
    max_stars: usize = default_max,
    star_px: f32 = default_size,
    /// Optional per-star listeners, parallel to the stars (may be null).
    on_stars: ?[]const zui.Listener = null,
    disabled_value: bool = false,

    pub fn init(value: f32) Rating {
        return .{ .value = value };
    }

    pub fn max(self: Rating, stars: usize) Rating {
        var copy = self;
        copy.max_stars = stars;
        return copy;
    }

    pub fn size(self: Rating, px: f32) Rating {
        var copy = self;
        copy.star_px = px;
        return copy;
    }

    /// One listener per star (1-based order). `null` renders read-only.
    pub fn onStars(self: Rating, listeners: []const zui.Listener) Rating {
        var copy = self;
        copy.on_stars = listeners;
        return copy;
    }

    pub fn disabled(self: Rating, value: bool) Rating {
        var copy = self;
        copy.disabled_value = value;
        return copy;
    }

    pub fn render(self: Rating) zui.Element {
        var row = zui.div().flex_row().items_center().gap(4);
        for (1..self.max_stars + 1) |index| {
            const filled = starState(self.value, index);
            var star = zui.div().size(self.star_px).flex_row().items_center().justify_center();
            if (!self.disabled_value) {
                if (self.on_stars) |listeners| {
                    if (index <= listeners.len) {
                        star = star.cursor_pointer().on_click(listeners[index - 1]);
                    }
                }
            }
            row = row.child(star.child(icon_component.render(
                .star,
                self.star_px,
                if (filled) filledColor() else emptyColor(),
            )));
        }
        if (self.disabled_value) row = row.opacity(0.5);
        return row;
    }
};

const std = @import("std");

test "star states follow the value with 1-based indices" {
    try std.testing.expect(starState(3.4, 1));
    try std.testing.expect(starState(3.4, 3));
    try std.testing.expect(!starState(3.4, 4));
    try std.testing.expect(!starState(3.4, 5));
    // Boundary: an exact value fills its own star.
    try std.testing.expect(starState(3.0, 3));
    try std.testing.expect(!starState(0, 1));
}

test "palette" {
    try std.testing.expectEqual(theme.warning, filledColor());
    try std.testing.expectEqual(theme.border_strong, emptyColor());
}
