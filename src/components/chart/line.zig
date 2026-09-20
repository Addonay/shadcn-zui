//! LineChart — one or more polylines (straight segments between samples),
//! optional dots, same scratch-buffer conventions as the area chart.

const std = @import("std");

const area = @import("area.zig");
const theme = @import("../../theme.zig");
const zui = @import("zui");

pub const Line = struct {
    values: []const f32,
    stroke: zui.Color = theme.foreground,
    stroke_px: f32 = 1.6,
    /// Draw a dot at every sample.
    dots: bool = false,
    /// Dot radius in SVG units.
    dot_radius: f32 = 2.5,
};

pub const default_width: f32 = 600;
pub const default_height: f32 = 240;

pub const side_pad: f32 = 8;
pub const top_pad: f32 = 8;
pub const bottom_pad: f32 = 8;
pub const default_grid_step: f32 = 100;

/// Peak across every line (0 when empty).
pub fn peakValue(lines: []const Line) f32 {
    var peak: f32 = 0;
    for (lines) |line| {
        for (line.values) |value| {
            if (value > peak) peak = value;
        }
    }
    return peak;
}

pub const LineChart = struct {
    lines: []const Line,
    svg_width: f32 = default_width,
    svg_height: f32 = default_height,
    grid_step: f32 = default_grid_step,

    pub fn init(lines: []const Line) LineChart {
        return .{ .lines = lines };
    }

    pub fn size(self: LineChart, width: f32, height: f32) LineChart {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn gridStep(self: LineChart, step: f32) LineChart {
        var copy = self;
        copy.grid_step = step;
        return copy;
    }

    pub fn buildSvg(self: LineChart, out: []u8) ?[]const u8 {
        var used: usize = 0;
        if (self.lines.len == 0) return null;

        // All lines share one sample count: the shortest.
        var n: usize = std.math.maxInt(usize);
        for (self.lines) |line| {
            if (line.values.len < n) n = line.values.len;
        }
        if (n < 2) return null;

        const peak = peakValue(self.lines);
        if (peak <= 0) return null;
        const domain = if (self.grid_step > 0) area.niceDomain(peak, self.grid_step) else peak * 1.1;

        const top = top_pad;
        const bottom = self.svg_height - bottom_pad;
        const left = side_pad;
        const right = self.svg_width - side_pad;
        const dx = (right - left) / (@as(f32, @floatFromInt(n)) - 1);

        var hex_buf: [9]u8 = undefined;

        put(&used, out, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{d}\" height=\"{d:.1}\" viewBox=\"0 0 {d} {d:.1}\">", .{ self.svg_width, self.svg_height, self.svg_width, self.svg_height });

        if (self.grid_step > 0) {
            var tick = self.grid_step;
            while (tick < domain) : (tick += self.grid_step) {
                const y = bottom - tick / domain * (bottom - top);
                put(&used, out, "<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"#262626\" stroke-width=\"1\"/>", .{ left, y, right, y });
            }
        }

        for (self.lines) |line| {
            var x = left;
            put(&used, out, "<path fill=\"none\" stroke=\"{s}\" stroke-width=\"{d:.1}\" d=\"M {d:.1} {d:.1}", .{ area.hexString(line.stroke, &hex_buf), line.stroke_px, x, yFor(line.values[0], domain, bottom, top) });
            for (1..n) |index| {
                x = left + @as(f32, @floatFromInt(index)) * dx;
                put(&used, out, " L {d:.1} {d:.1}", .{ x, yFor(line.values[index], domain, bottom, top) });
            }
            put(&used, out, "\"/>", .{});

            if (line.dots) {
                x = left;
                for (line.values[0..n], 0..) |value, index| {
                    x = left + @as(f32, @floatFromInt(index)) * dx;
                    put(&used, out, "<circle cx=\"{d:.1}\" cy=\"{d:.1}\" r=\"{d:.1}\" fill=\"{s}\"/>", .{ x, yFor(value, domain, bottom, top), line.dot_radius, area.hexString(line.stroke, &hex_buf) });
                }
            }
        }

        put(&used, out, "</svg>", .{});
        if (used > out.len) return null;
        return out[0..used];
    }

    pub fn render(self: LineChart, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse "";
        return zui.svg(svg).w_full().h(self.svg_height);
    }
};

fn yFor(value: f32, domain: f32, bottom: f32, top: f32) f32 {
    return bottom - value / domain * (bottom - top);
}

fn put(used: *usize, out: []u8, comptime format: []const u8, args: anytype) void {
    if (used.* >= out.len) {
        used.* = out.len + 1;
        return;
    }
    const text = std.fmt.bufPrint(out[used.*..], format, args) catch {
        used.* = out.len + 1;
        return;
    };
    used.* += text.len;
}

test "line count respects the shortest series" {
    const lines = [_]Line{
        .{ .values = &.{ 10, 20, 30, 40 }, .stroke = theme.foreground },
        .{ .values = &.{ 5, 10 }, .stroke = theme.faint },
    };
    const chart = LineChart.init(&lines);
    var scratch: [4096]u8 = undefined;
    const svg = chart.buildSvg(&scratch) orelse return error.TestUnexpectedResult;
    // Two strokes; dots off by default.
    try std.testing.expectEqual(@as(usize, 2), std.mem.count(u8, svg, "<path"));
    try std.testing.expectEqual(@as(usize, 0), std.mem.count(u8, svg, "<circle"));
}

test "dots render one circle per sample" {
    const lines = [_]Line{.{ .values = &.{ 10, 20, 30 }, .stroke = theme.foreground, .dots = true }};
    const chart = LineChart.init(&lines);
    var scratch: [4096]u8 = undefined;
    const svg = chart.buildSvg(&scratch) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(@as(usize, 3), std.mem.count(u8, svg, "<circle"));
}

test "degenerate input returns null" {
    const lines = [_]Line{.{ .values = &.{10} }};
    var scratch: [4096]u8 = undefined;
    try std.testing.expect(LineChart.init(&lines).buildSvg(&scratch) == null);

    const empty_lines = [_]Line{};
    try std.testing.expect(LineChart.init(&empty_lines).buildSvg(&scratch) == null);
}
