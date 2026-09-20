//! ScatterChart / BubbleChart — point cloud, optional radius-by-value.

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const MAX_POINTS: usize = 256;

pub const Point = struct {
    x: f32,
    y: f32,
    /// Bubble radius factor in 0..1 (used when `radius_by_value` is set).
    weight: f32 = 0.5,
};

pub const ScatterChart = struct {
    points: []const Point,
    fill: zui.Color = theme.chart_2,
    svg_width: f32 = 560,
    svg_height: f32 = 280,
    /// Fixed point radius; when > 0 points are circles of this size.
    point_px: f32 = 6,
    /// Map point weight 0..1 to this radius range (bubble mode).
    radius_by_value: bool = false,
    max_radius_px: f32 = 22,
    min_radius_px: f32 = 4,
    x_domain_max: f32 = 1,
    y_domain_max: f32 = 1,
    top_pad: f32 = 10,
    bottom_pad: f32 = 10,
    side_pad: f32 = 10,

    pub fn init(points: []const Point) ScatterChart {
        return .{ .points = points };
    }

    pub fn size(self: ScatterChart, width: f32, height: f32) ScatterChart {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn color(self: ScatterChart, value: zui.Color) ScatterChart {
        var copy = self;
        copy.fill = value;
        return copy;
    }

    /// Bubble mode: radius scales with each point's weight.
    pub fn bubble(self: ScatterChart) ScatterChart {
        var copy = self;
        copy.radius_by_value = true;
        return copy;
    }

    /// Largest radius this chart can emit (pure).
    pub fn maxRadius(self: ScatterChart) f32 {
        return if (self.radius_by_value) self.max_radius_px else self.point_px;
    }

    /// Plot bounds inset by the largest radius so circles never cross the
    /// axes or the SVG edge (pure). Falls back to the plain pads when the
    /// SVG is too small to fit the inset.
    pub fn plotBounds(self: ScatterChart) struct { left: f32, right: f32, top: f32, bottom: f32 } {
        const max_r = self.maxRadius();
        const left = self.side_pad + max_r;
        const right = self.svg_width - self.side_pad - max_r;
        const top = self.top_pad + max_r;
        const bottom = self.svg_height - self.bottom_pad - max_r;
        if (right <= left or bottom <= top) {
            return .{
                .left = self.side_pad,
                .right = self.svg_width - self.side_pad,
                .top = self.top_pad,
                .bottom = self.svg_height - self.bottom_pad,
            };
        }
        return .{ .left = left, .right = right, .top = top, .bottom = bottom };
    }

    pub fn buildSvg(self: ScatterChart, out: []u8) ?[]const u8 {
        if (self.points.len == 0) return null;
        var hex_buf: [9]u8 = undefined;
        const fill = area.hexString(self.fill, &hex_buf);

        const axes_left = self.side_pad;
        const axes_right = self.svg_width - self.side_pad;
        const axes_top = self.top_pad;
        const axes_bottom = self.svg_height - self.bottom_pad;

        // Centers stay inset by the largest radius so no circle crosses an
        // axis; axes themselves sit at the plain pads.
        const plot = self.plotBounds();

        var peak_y: f32 = 1;
        var peak_x: f32 = 1;
        for (self.points) |point| {
            if (point.y > peak_y) peak_y = point.y;
            if (point.x > peak_x) peak_x = point.x;
        }

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        // Axes.
        geometry.putRect(&w, axes_left, axes_bottom - 1, axes_right - axes_left, 1, "#343434", 0);
        geometry.putRect(&w, axes_left, axes_top, 1, axes_bottom - axes_top, "#343434", 0);

        for (self.points) |point| {
            const x = geometry.map(point.x, 0, peak_x, plot.left, plot.right);
            const y = geometry.map(point.y, 0, peak_y, plot.bottom, plot.top);
            const weight = std.math.clamp(point.weight, 0, 1);
            const radius = if (self.radius_by_value)
                self.min_radius_px + weight * (self.max_radius_px - self.min_radius_px)
            else
                self.point_px;
            geometry.putCircle(&w, x, y, radius, fill);
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    pub fn render(self: ScatterChart, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "bubble radius spreads" {
    const chart = ScatterChart.init(&.{}).bubble();
    try std.testing.expect(chart.max_radius_px > chart.min_radius_px);
}

test "plot bounds inset by largest radius" {
    const chart = ScatterChart.init(&.{.{ .x = 0, .y = 0 }}).bubble().size(560, 280);
    const plot = chart.plotBounds();
    try std.testing.expectApproxEqAbs(@as(f32, 10 + 22), plot.left, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 560 - 10 - 22), plot.right, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 10 + 22), plot.top, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 280 - 10 - 22), plot.bottom, 0.001);
}

test "out-of-range weight clamps instead of overflowing radius" {
    const pts = [_]Point{.{ .x = 1, .y = 1, .weight = 5 }};
    const chart = ScatterChart.init(pts[0..]).bubble().size(200, 120);
    var buf: [4096]u8 = undefined;
    const svg = chart.buildSvg(&buf) orelse return error.TestUnexpectedResult;
    // Largest radius is 22.0; a weight of 5 must not emit r="94.0".
    try std.testing.expect(std.mem.indexOf(u8, svg, "r=\"22.0\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, svg, "r=\"94.0\"") == null);
}
