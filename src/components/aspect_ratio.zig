//! AspectRatio — shadcn/ui's ratio-constrained box.
//!
//! ```zig
//! AspectRatio.init(16.0 / 9.0).width(640).content(element).render()
//! ```

const zui = @import("zui");

/// Height a given width needs to honor a width/height ratio (pure).
pub fn heightFor(width: f32, ratio: f32) f32 {
    if (ratio <= 0) return 0;
    return width / ratio;
}

pub const AspectRatio = struct {
    /// width / height; 1 is square, 16/9 is wide video.
    ratio_value: f32,
    width_px: f32 = 320,
    content_value: ?zui.Element = null,

    pub fn init(ratio: f32) AspectRatio {
        return .{ .ratio_value = ratio };
    }

    pub fn width(self: AspectRatio, px: f32) AspectRatio {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn content(self: AspectRatio, element: zui.Element) AspectRatio {
        var copy = self;
        copy.content_value = element;
        return copy;
    }

    pub fn render(self: AspectRatio) zui.Element {
        var frame = zui.div().w(self.width_px).h(heightFor(self.width_px, self.ratio_value))
            .rounded_lg();
        if (self.content_value) |element| frame = frame.child(element);
        return frame;
    }
};

const std = @import("std");

test "height honors and guards ratio" {
    try std.testing.expectEqual(@as(f32, 360), heightFor(640, 16.0 / 9.0));
    try std.testing.expectEqual(@as(f32, 320), heightFor(320, 1));
    try std.testing.expectEqual(@as(f32, 0), heightFor(640, 0));
}
