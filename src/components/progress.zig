//! Progress — shadcn/ui's track-and-fill bar. Controlled, presentational.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const default_width: f32 = 320;
pub const default_height: f32 = 8;

/// Fill width for a fraction value (clamped to 0..1) across `width` px.
pub fn fillWidth(value: f32, width: f32) f32 {
    const clamped = std.math.clamp(value, 0, 1);
    return clamped * width;
}

pub const Progress = struct {
    /// Fraction of the track that is filled, 0..1 (clamped).
    value: f32 = 0,
    width_px: f32 = default_width,
    height_px: f32 = default_height,
    /// Optional caller-owned percent label ("62%") shown after the track.
    percent_text: ?[]const u8 = null,

    pub fn init(value: f32) Progress {
        return .{ .value = value };
    }

    pub fn width(self: Progress, px: f32) Progress {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn height(self: Progress, px: f32) Progress {
        var copy = self;
        copy.height_px = px;
        return copy;
    }

    /// Text slices are borrowed until paint: pass a string your state owns
    /// (e.g. formatted into a state buffer when the value changes).
    pub fn percentText(self: Progress, text: []const u8) Progress {
        var copy = self;
        copy.percent_text = text;
        return copy;
    }

    pub fn render(self: Progress) zui.Element {
        const track = zui.div().w(self.width_px).h(self.height_px).rounded_full()
            .bg(theme.secondary)
            .child(zui.div().w(fillWidth(self.value, self.width_px)).h(self.height_px)
            .rounded_full().bg(theme.primary));
        if (self.percent_text) |text| {
            return zui.div().flex_row().items_center().gap(8)
                .child(track)
                .child(support.label(text, 12, theme.muted_foreground));
        }
        return track;
    }
};

const std = @import("std");

test "fill width clamps and scales" {
    try std.testing.expectEqual(@as(f32, 0), fillWidth(0, 320));
    try std.testing.expectEqual(@as(f32, 160), fillWidth(0.5, 320));
    try std.testing.expectEqual(@as(f32, 320), fillWidth(1, 320));
    try std.testing.expectEqual(@as(f32, 320), fillWidth(1.5, 320));
    try std.testing.expectEqual(@as(f32, 0), fillWidth(-0.2, 320));
}
