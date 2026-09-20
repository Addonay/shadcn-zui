//! Stacked — layered series: StackedAreaChart and StackedBarChart.

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const MAX_STACK: usize = 8;
pub const MAX_POINTS: usize = 256;

/// Per-index stacking: bottom offsets and tops for series i (pure).
pub fn cumulativeAt(series: []const []const f32, index: usize, out: []f32) usize {
    var running: f32 = 0;
    var count: usize = 0;
    for (series) |values| {
        if (index < values.len) {
            running += values[index];
        }
        if (count < out.len) {
            out[count] = running;
            count += 1;
        }
    }
    return count;
}

pub const StackedAreaChart = struct {
    series: []const []const f32 = &.{},
    fills: []const zui.Color = &.{},
    strokes: []const zui.Color = &.{},
    svg_width: f32 = 1200,
    svg_height: f32 = 260,
    grid_step: f32 = 250,
    top_pad: f32 = 8,
    bottom_pad: f32 = 8,
    side_pad: f32 = 10,

    pub fn init(series: []const []const f32) StackedAreaChart {
        return .{ .series = series };
    }

    pub fn size(self: StackedAreaChart, width: f32, height: f32) StackedAreaChart {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn paletteFor(self: StackedAreaChart, fills: []const zui.Color, strokes: []const zui.Color) StackedAreaChart {
        var copy = self;
        copy.fills = fills;
        copy.strokes = strokes;
        return copy;
    }

    pub fn buildSvg(self: StackedAreaChart, out: []u8) ?[]const u8 {
        if (self.series.len == 0 or self.series.len > MAX_STACK) return null;
        var n: usize = MAX_POINTS;
        for (self.series) |values| n = @min(n, values.len);
        if (n < 2) return null;

        // Stacked totals at each index.
        var totals: [MAX_POINTS]f32 = undefined;
        var i: usize = 0;
        while (i < n) : (i += 1) {
            var running: f32 = 0;
            for (self.series) |values| running += values[i];
            totals[i] = running;
        }
        var peak: f32 = 0;
        for (totals[0..n]) |value| peak = @max(peak, value);
        const domain = area.niceDomain(peak, self.grid_step);

        const top = self.top_pad;
        const bottom = self.svg_height - self.bottom_pad;
        const left = self.side_pad;
        const right = self.svg_width - self.side_pad;
        const dx = (right - left) / @as(f32, @floatFromInt(n - 1));

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        // Draw series bottom-up: each band between the previous top and its own top.
        var bottoms: [MAX_POINTS]f32 = undefined;
        @memset(&bottoms, bottom);
        var series_index: usize = 0;
        while (series_index < self.series.len) : (series_index += 1) {
            var hex_buf: [9]u8 = undefined;
            var stroke_buf: [9]u8 = undefined;
            const fill = area.hexString(self.colorAt(series_index), &hex_buf);
            const stroke = area.hexString(self.strokeAt(series_index), &stroke_buf);

            w.print("<path d=\"", .{});
            // Top edge: previous bottom + this series' own value.
            var point_index: usize = 0;
            while (point_index < n) : (point_index += 1) {
                const x = left + @as(f32, @floatFromInt(point_index)) * dx;
                const y_cum = bottom - (bottoms[point_index] + self.series[series_index][point_index]) / domain * (bottom - top);
                if (point_index == 0) {
                    w.print("M {d:.1} {d:.1}", .{ x, y_cum });
                } else {
                    w.print(" L {d:.1} {d:.1}", .{ x, y_cum });
                }
            }
            // Back along the previous top.
            var back: usize = n;
            while (back > 0) : (back -= 1) {
                const x = left + @as(f32, @floatFromInt(back - 1)) * dx;
                const y_base = bottom - bottoms[back - 1] / domain * (bottom - top);
                w.print(" L {d:.1} {d:.1}", .{ x, y_base });
            }
            w.print(" Z\" fill=\"{s}\" stroke=\"{s}\" stroke-width=\"1.5\"/>", .{ fill, stroke });

            // This series' top becomes the next band's bottom.
            point_index = 0;
            while (point_index < n) : (point_index += 1) {
                bottoms[point_index] += self.series[series_index][point_index];
            }
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    fn colorAt(self: StackedAreaChart, index: usize) zui.Color {
        if (self.fills.len == 0) return theme.chart_1;
        return self.fills[index % self.fills.len];
    }

    fn strokeAt(self: StackedAreaChart, index: usize) zui.Color {
        if (self.strokes.len == 0) return theme.foreground;
        return self.strokes[index % self.strokes.len];
    }

    pub fn render(self: StackedAreaChart, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

pub const StackedBarChart = struct {
    /// Per group: one value per series (series-major slices, row-major).
    groups: []const []const f32 = &.{},
    fills: []const zui.Color = &.{},
    svg_width: f32 = 1200,
    svg_height: f32 = 260,
    grid_step: f32 = 250,
    bar_gap: f32 = 8,
    top_pad: f32 = 8,
    bottom_pad: f32 = 8,

    pub fn init(groups: []const []const f32) StackedBarChart {
        return .{ .groups = groups };
    }

    pub fn size(self: StackedBarChart, width: f32, height: f32) StackedBarChart {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn paletteFor(self: StackedBarChart, fills: []const zui.Color) StackedBarChart {
        var copy = self;
        copy.fills = fills;
        return copy;
    }

    pub fn buildSvg(self: StackedBarChart, out: []u8) ?[]const u8 {
        const group_count = self.groups.len;
        if (group_count == 0) return null;
        const series_count = self.groups[0].len;
        if (series_count == 0 or series_count > MAX_STACK) return null;

        var peak: f32 = 0;
        for (self.groups) |group| {
            if (group.len != series_count) return null;
            var running: f32 = 0;
            for (group) |value| running += value;
            peak = @max(peak, running);
        }
        const domain = area.niceDomain(peak, self.grid_step);

        const top = self.top_pad;
        const bottom = self.svg_height - self.bottom_pad;
        const slot = (self.svg_width - 2 * self.bar_gap) / @as(f32, @floatFromInt(group_count));
        const bar_w = slot * 0.7;

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        var group_index: usize = 0;
        while (group_index < group_count) : (group_index += 1) {
            const center = self.bar_gap + slot * (@as(f32, @floatFromInt(group_index)) + 0.5);
            var running: f32 = 0;
            var series_index: usize = 0;
            while (series_index < series_count) : (series_index += 1) {
                var hex_buf: [9]u8 = undefined;
                const fill = area.hexString(self.colorAt(series_index), &hex_buf);
                const from = running;
                running += self.groups[group_index][series_index];
                const top_y = bottom - (running / domain) * (bottom - top);
                const bottom_y = bottom - (from / domain) * (bottom - top);
                geometry.putRect(&w, center - bar_w / 2, top_y, bar_w, @max(1, bottom_y - top_y), fill, 2);
            }
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    fn colorAt(self: StackedBarChart, index: usize) zui.Color {
        if (self.fills.len == 0) {
            return switch (index % 3) {
                0 => theme.chart_1,
                1 => theme.chart_2,
                else => theme.chart_3,
            };
        }
        return self.fills[index % self.fills.len];
    }

    pub fn render(self: StackedBarChart, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "cumulativeAt stacks" {
    const a = [_]f32{ 1, 2 };
    const b = [_]f32{ 3, 4 };
    var out: [MAX_STACK]f32 = undefined;
    const count = cumulativeAt(&.{ &a, &b }, 1, &out);
    try std.testing.expectEqual(@as(usize, 2), count);
    try std.testing.expectEqual(@as(f32, 2), out[0]);
    try std.testing.expectEqual(@as(f32, 6), out[1]);
}
