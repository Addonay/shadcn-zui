//! Shimmer — gpui-kit's pulsing opacity sweep over any element.
//! The app drives the alpha from the clock: `alpha = shimmer.alphaFor(ms)`.

const zui = @import("zui");

pub const period_ms: i64 = 1200;
pub const min_alpha: f32 = 0.35;

/// Opacity for a time value across one pulse (pure; unit-tested).
pub fn alphaFor(ms: i64) f32 {
    const phase = @as(f32, @floatFromInt(@mod(ms, period_ms))) / @as(f32, @floatFromInt(period_ms));
    const triangle = if (phase <= 0.5) phase * 2 else (1.0 - phase) * 2.0;
    return min_alpha + (1.0 - min_alpha) * triangle;
}

pub const Shimmer = struct {
    child_element: zui.Element,
    /// Alpha in 0..1 (call `alphaFor(ms)` each frame while animating).
    alpha_value: f32 = 1,

    pub fn init(child: zui.Element) Shimmer {
        return .{ .child_element = child };
    }

    pub fn alpha(self: Shimmer, value: f32) Shimmer {
        var copy = self;
        copy.alpha_value = value;
        return copy;
    }

    pub fn render(self: Shimmer) zui.Element {
        return zui.div().opacity(self.alpha_value).child(self.child_element);
    }
};

const std = @import("std");

test "alpha sweeps the range" {
    try std.testing.expectEqual(@as(f32, min_alpha), alphaFor(0));
    try std.testing.expectEqual(@as(f32, 1), alphaFor(period_ms / 2));
    try std.testing.expectEqual(@as(f32, min_alpha), alphaFor(period_ms));
    try std.testing.expect(alphaFor(300) > alphaFor(0));
}
