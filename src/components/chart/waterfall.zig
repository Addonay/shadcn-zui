//! Waterfall — running-sum floating bars (ECharts-style P&L breakdown).

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

/// Running totals before each step (pure; unit-tested). The first entry is
/// the implicit 0 baseline; `out` must hold values.len + 1 entries.
pub fn cumulative(values: []const f32, out: []f32) []f32 {
    out[0] = 0;
    var index: usize = 0;
    while (index < values.len) : (index += 1) {
        out[index + 1] = out[index] + values[index];
    }
    return out[0 .. values.len + 1];
}

pub const Waterfall = struct {
    /// Positive/negative deltas from the running total.
    values: []const f32 = &.{},
    labels: []const []const u8 = &.{},
    svg_width: f32 = 560,
    svg_height: f32 = 280,
    up: zui.Color = theme.success,
    down: zui.Color = theme.destructive,
    total_color: zui.Color = theme.ring,
    bar_gap: f32 = 8,
    top_pad: f32 = 10,
    bottom_pad: f32 = 10,

    pub fn init(values: []const f32) Waterfall {
        return .{ .values = values };
    }

    pub fn size(self: Waterfall, width: f32, height: f32) Waterfall {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn buildSvg(self: Waterfall, out: []u8) ?[]const u8 {
        const n = self.values.len;
        if (n == 0) return null;

        var totals_buf: [129]f32 = undefined;
        if (n + 1 > totals_buf.len) return null;
        const totals = cumulative(self.values, &totals_buf);

        var peak: f32 = 0;
        for (totals) |value| peak = @max(peak, @abs(value));
        if (peak <= 0) return null;

        const top = self.top_pad;
        const bottom = self.svg_height - self.bottom_pad;
        const slot = (self.svg_width - 2 * self.bar_gap) / @as(f32, @floatFromInt(n + 1));
        const body_w = slot * 0.7;

        var up_buf: [9]u8 = undefined;
        var down_buf: [9]u8 = undefined;
        var total_buf: [9]u8 = undefined;
        const up_fill = area.hexString(self.up, &up_buf);
        const down_fill = area.hexString(self.down, &down_buf);
        const total_fill = area.hexString(self.total_color, &total_buf);

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        var index: usize = 0;
        while (index < n) : (index += 1) {
            const start = totals[index];
            const end = totals[index + 1];
            const going_up = end >= start;
            const top_y = bottom - (@max(start, end) / peak) * (bottom - top);
            const bottom_y = bottom - (@min(start, end) / peak) * (bottom - top);
            const center = self.bar_gap + slot * (@as(f32, @floatFromInt(index)) + 0.5);
            const fill = if (going_up) up_fill else down_fill;
            geometry.putRect(&w, center - body_w / 2, top_y, body_w, @max(1, bottom_y - top_y), fill, 3);
        }
        // Final total bar.
        {
            const center = self.bar_gap + slot * (@as(f32, @floatFromInt(n)) + 0.5);
            const total = totals[n];
            const top_y = bottom - (total / peak) * (bottom - top);
            geometry.putRect(&w, center - body_w / 2, top_y, body_w, @max(1, bottom - top_y), total_fill, 3);
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    pub fn render(self: Waterfall, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "cumulative sums" {
    var totals: [4]f32 = undefined;
    const result = cumulative(&.{ 5, -2, 4 }, &totals);
    try std.testing.expectEqual(@as(usize, 4), result.len);
    try std.testing.expectEqual(@as(f32, 0), result[0]);
    try std.testing.expectEqual(@as(f32, 5), result[1]);
    try std.testing.expectEqual(@as(f32, 3), result[2]);
    try std.testing.expectEqual(@as(f32, 7), result[3]);
}
