//! Skeleton — shadcn/ui's loading placeholder block.
//!
//! zui has no CSS animations; apps that want the pulse effect alternate
//! `Skeleton.shimmer()` colors from their frame loop (the component stays
//! allocation-free and static).

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const default_width: f32 = 200;
pub const default_height: f32 = 16;
pub const default_radius: f32 = 8;

/// Resting block color.
pub fn blockColor() zui.Color {
    return theme.muted;
}

/// Slightly lighter pulse phase color.
pub fn shimmerColor() zui.Color {
    return theme.accent;
}

pub const Skeleton = struct {
    width_px: ?f32 = null,
    height_px: ?f32 = null,
    radius_px: ?f32 = null,
    circle_value: bool = false,
    /// Swap to the pulse phase color (drive from the app's frame clock).
    shimmer: bool = false,

    pub fn init() Skeleton {
        return .{};
    }

    pub fn width(self: Skeleton, px: f32) Skeleton {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn height(self: Skeleton, px: f32) Skeleton {
        var copy = self;
        copy.height_px = px;
        return copy;
    }

    pub fn rounded(self: Skeleton, px: f32) Skeleton {
        var copy = self;
        copy.radius_px = px;
        return copy;
    }

    pub fn circle(self: Skeleton) Skeleton {
        var copy = self;
        copy.circle_value = true;
        return copy;
    }

    pub fn render(self: Skeleton) zui.Element {
        const w = if (self.circle_value) self.height_px orelse default_height else self.width_px orelse default_width;
        const h = self.height_px orelse default_height;
        var block = zui.div().w(w).h(h).bg(if (self.shimmer) shimmerColor() else blockColor());
        block = if (self.circle_value) block.rounded_full() else block.rounded(self.radius_px orelse default_radius);
        return block;
    }
};

const std = @import("std");

test "skeleton metrics" {
    try std.testing.expectEqual(theme.muted, blockColor());
    try std.testing.expectEqual(theme.accent, shimmerColor());
    try std.testing.expectEqual(@as(f32, 16), default_height);
}
