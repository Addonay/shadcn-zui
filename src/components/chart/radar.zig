//! Radar — ECharts/Recharts polar radar chart.

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const Radar = struct {
    /// One series per polygon; values are 0..1 fractions per axis.
    series: []const []const f32 = &.{},
    fills: []const zui.Color = &.{},
    axis_count: usize = 6,
    svg_width: f32 = 280,
    rings: usize = 4,

    pub fn init(series: []const []const f32) Radar {
        return .{ .series = series };
    }

    pub fn size(self: Radar, px: f32) Radar {
        var copy = self;
        copy.svg_width = px;
        return copy;
    }

    pub fn paletteFor(self: Radar, colors: []const zui.Color) Radar {
        var copy = self;
        copy.fills = colors;
        return copy;
    }

    pub fn buildSvg(self: Radar, out: []u8) ?[]const u8 {
        if (self.axis_count < 3) return null;
        for (self.series) |values| {
            if (values.len != self.axis_count) return null;
        }
        const center = self.svg_width / 2;
        const radius = center - 12;

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_width);

        // Rings (polygons at scaled radii).
        var ring: usize = 1;
        while (ring <= self.rings) : (ring += 1) {
            const r = radius * (@as(f32, @floatFromInt(ring)) / @as(f32, @floatFromInt(self.rings)));
            var ring_path_buf: [1024]u8 = undefined;
            w.print("<path d=\"{s}\" fill=\"none\" stroke=\"#262626\" stroke-width=\"1\"/>", .{
                axisPath(center, center, r, self.axis_count, &ring_path_buf),
            });
        }
        // Spokes.
        var axis: usize = 0;
        while (axis < self.axis_count) : (axis += 1) {
            const angle = @as(f32, @floatFromInt(axis)) * 360.0 / @as(f32, @floatFromInt(self.axis_count));
            const end = geometry.polarPoint(center, center, radius, angle);
            w.print("<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"#262626\" stroke-width=\"1\"/>", .{
                center, center, end.x, end.y,
            });
        }
        // Series polygons.
        var series_buf: [2048]u8 = undefined;
        for (self.series, 0..) |values, series_index| {
            var hex_buf: [9]u8 = undefined;
            const fill = area.hexString(self.colorFor(series_index), &hex_buf);
            w.print("<path d=\"{s}\" fill=\"{s}\" opacity=\"0.35\" stroke=\"{s}\" stroke-width=\"2\"/>", .{
                seriesPath(center, center, radius, values, &series_buf),
                fill,
                fill,
            });
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    fn colorFor(self: Radar, index: usize) zui.Color {
        if (self.fills.len == 0) {
            return switch (index % 3) {
                0 => theme.chart_1,
                1 => theme.chart_2,
                else => theme.chart_3,
            };
        }
        return self.fills[index % self.fills.len];
    }

    pub fn render(self: Radar, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

/// Regular polygon path for a ring/spoke frame (pure given the buffer).
pub fn axisPath(cx: f32, cy: f32, radius: f32, count: usize, buf: []u8) []const u8 {
    var w = geometry.Writer{ .buffer = buf };
    var axis: usize = 0;
    while (axis < count) : (axis += 1) {
        const angle = @as(f32, @floatFromInt(axis)) * 360.0 / @as(f32, @floatFromInt(count));
        const vertex = geometry.polarPoint(cx, cy, radius, angle);
        if (axis == 0) {
            w.print("M {d:.1} {d:.1}", .{ vertex.x, vertex.y });
        } else {
            w.print(" L {d:.1} {d:.1}", .{ vertex.x, vertex.y });
        }
    }
    w.append(" Z");
    return w.slice() orelse "";
}

/// Polygon path for one series' fractions (pure given the buffer).
pub fn seriesPath(cx: f32, cy: f32, radius: f32, values: []const f32, buf: []u8) []const u8 {
    var w = geometry.Writer{ .buffer = buf };
    var axis: usize = 0;
    while (axis < values.len) : (axis += 1) {
        const angle = @as(f32, @floatFromInt(axis)) * 360.0 / @as(f32, @floatFromInt(values.len));
        const r = radius * std.math.clamp(values[axis], 0, 1);
        const vertex = geometry.polarPoint(cx, cy, r, angle);
        if (axis == 0) {
            w.print("M {d:.1} {d:.1}", .{ vertex.x, vertex.y });
        } else {
            w.print(" L {d:.1} {d:.1}", .{ vertex.x, vertex.y });
        }
    }
    w.append(" Z");
    return w.slice() orelse "";
}

test "axis path closes" {
    var buf: [256]u8 = undefined;
    const path = axisPath(100, 100, 40, 6, &buf);
    try std.testing.expect(std.mem.endsWith(u8, path, " Z"));
}

test "radar rejects unusable data" {
    const chart = Radar.init(&mismatched_series);
    var scratch: [8192]u8 = undefined;
    try std.testing.expect(chart.buildSvg(&scratch) == null);
}

const mismatched_series = [_][]const f32{
    &.{ 0.2, 0.4, 0.6, 0.8, 1.0 },
    &.{ 0.1, 0.2, 0.3, 0.4, 0.5, 0.6 },
};
