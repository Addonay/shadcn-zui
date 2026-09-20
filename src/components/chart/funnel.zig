//! FunnelChart — ECharts/Recharts' centered trapezoid funnel.

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const FunnelChart = struct {
    values: []const f32 = &.{},
    palette: []const zui.Color = &.{},
    svg_width: f32 = 420,
    svg_height: f32 = 300,
    top_pad: f32 = 6,
    bottom_pad: f32 = 6,
    side_pad: f32 = 40,
    gap: f32 = 4,

    pub fn init(values: []const f32) FunnelChart {
        return .{ .values = values };
    }

    pub fn size(self: FunnelChart, width: f32, height: f32) FunnelChart {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn paletteFor(self: FunnelChart, colors: []const zui.Color) FunnelChart {
        var copy = self;
        copy.palette = colors;
        return copy;
    }

    pub fn buildSvg(self: FunnelChart, out: []u8) ?[]const u8 {
        const n = self.values.len;
        if (n == 0) return null;

        var peak: f32 = 0;
        for (self.values) |value| peak = @max(peak, value);
        if (peak <= 0) return null;

        const usable_h = self.svg_height - self.top_pad - self.bottom_pad;
        const seg_h = (usable_h - self.gap * @as(f32, @floatFromInt(n - 1))) / @as(f32, @floatFromInt(n));
        const center_x = self.svg_width / 2;
        const max_half = self.svg_width / 2 - self.side_pad;
        // Minimum half-width keeps the last segment readable.
        const min_half: f32 = 12;

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        var y = self.top_pad;
        var prev_half: ?f32 = null;
        for (self.values, 0..) |value, index| {
            const frac = value / peak;
            const half = min_half + frac * (max_half - min_half);
            var hex_buf: [9]u8 = undefined;
            const fill = area.hexString(self.colorFor(index), &hex_buf);
            const bottom_y = y + seg_h;
            const top_half = prev_half orelse half;
            w.print("<path d=\"M {d:.1} {d:.1} L {d:.1} {d:.1} L {d:.1} {d:.1} L {d:.1} {d:.1} Z\" fill=\"{s}\"/>", .{
                center_x - top_half, y,
                center_x + top_half, y,
                center_x + half,     bottom_y,
                center_x - half,     bottom_y,
                fill,
            });
            prev_half = half;
            y = bottom_y + self.gap;
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    fn colorFor(self: FunnelChart, index: usize) zui.Color {
        if (self.palette.len == 0) {
            return switch (index % 3) {
                0 => theme.chart_1,
                1 => theme.chart_2,
                else => theme.chart_3,
            };
        }
        return self.palette[index % self.palette.len];
    }

    pub fn render(self: FunnelChart, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "funnel needs values" {
    const chart = FunnelChart.init(&.{});
    var scratch: [4096]u8 = undefined;
    try std.testing.expect(chart.buildSvg(&scratch) == null);
}
