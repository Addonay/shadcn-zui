//! PieChart — wedge chart rendered as SVG, with optional donut hole.
//!
//! Arcs are polylines (short segments), which nanosvg rasterizes exactly
//! the same as arcs but keeps the generator trivial and testable. Slices
//! start at 12 o'clock and wind clockwise; zero-value slices are skipped.

const std = @import("std");

const area = @import("area.zig");
const theme = @import("../../theme.zig");
const zui = @import("zui");

pub const Slice = struct {
    value: f32,
    fill: zui.Color,
    /// Optional stroke around the wedge (defaults to the theme border so
    /// adjacent slices read separately).
    stroke: ?zui.Color = null,
    stroke_px: f32 = 1.2,
};

pub const default_size: f32 = 220;

/// Angle step of the arc polylines, in degrees (smaller = rounder).
pub const arc_step_deg: f32 = 6;

pub const default_inner_radius: f32 = 0;

pub const PieChart = struct {
    slices: []const Slice,
    size_px: f32 = default_size,
    inner_radius: f32 = default_inner_radius,

    pub fn init(slices: []const Slice) PieChart {
        return .{ .slices = slices };
    }

    pub fn size(self: PieChart, px: f32) PieChart {
        var copy = self;
        copy.size_px = px;
        return copy;
    }

    /// 0 = pie; `inner_radius > 0` renders a donut (use `size_px * 0.6`).
    pub fn innerRadius(self: PieChart, px: f32) PieChart {
        var copy = self;
        copy.inner_radius = px;
        return copy;
    }

    pub fn buildSvg(self: PieChart, out: []u8) ?[]const u8 {
        var used: usize = 0;
        var total: f32 = 0;
        for (self.slices) |slice| total += slice.value;
        if (self.slices.len == 0 or total <= 0) return null;

        const radius = self.size_px / 2 - 2;
        const cx = self.size_px / 2;
        const cy = self.size_px / 2;
        const inner = if (self.inner_radius > 0) @min(self.inner_radius, radius - 1) else 0;

        var fill_hex_buf: [9]u8 = undefined;
        var stroke_hex_buf: [9]u8 = undefined;
        // Each wedge path is composed here first (longest wedge ~60 steps
        // x ~20 bytes), then spliced into the SVG.
        var wedge_buf: [4096]u8 = undefined;

        put(&used, out, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{d}\" height=\"{d}\" viewBox=\"0 0 {d} {d}\">", .{ self.size_px, self.size_px, self.size_px, self.size_px });

        var start_deg: f32 = -90;
        for (self.slices) |slice| {
            if (slice.value <= 0) continue;
            const sweep = slice.value / total * 360.0;
            put(&used, out, "<path fill=\"{s}\" stroke=\"{s}\" stroke-width=\"{d:.1}\" d=\"{s}\"/>", .{
                area.hexString(slice.fill, &fill_hex_buf),
                area.hexString(slice.stroke orelse theme.background, &stroke_hex_buf),
                slice.stroke_px,
                wedgePath(cx, cy, radius, inner, start_deg, sweep, &wedge_buf) orelse return null,
            });
            start_deg += sweep;
        }

        put(&used, out, "</svg>", .{});
        if (used > out.len) return null;
        return out[0..used];
    }

    pub fn render(self: PieChart, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse "";
        return zui.svg(svg).size(self.size_px);
    }
};

/// The `d` attribute for one wedge: outer arc polyline closed to the center
/// (pie) or to the inner arc (donut). Composed into `path_out`; null on
/// overflow.
fn wedgePath(cx: f32, cy: f32, radius: f32, inner_radius: f32, start_deg: f32, sweep_deg: f32, path_out: []u8) ?[]const u8 {
    var used: usize = 0;
    const start = point(cx, cy, radius, start_deg);
    put(&used, path_out, "M {d:.1} {d:.1}", .{ start.x, start.y });

    const steps = @max(2, @as(usize, @intFromFloat(@ceil(sweep_deg / arc_step_deg))));
    var step_index: usize = 1;
    while (step_index <= steps) : (step_index += 1) {
        const frac = @min(1, @as(f32, @floatFromInt(step_index)) / @as(f32, @floatFromInt(steps)));
        const angle = start_deg + sweep_deg * frac;
        const point_outer = point(cx, cy, radius, angle);
        put(&used, path_out, " L {d:.1} {d:.1}", .{ point_outer.x, point_outer.y });
    }

    if (inner_radius > 0) {
        var back: usize = steps;
        while (back > 0) : (back -= 1) {
            const frac = @as(f32, @floatFromInt(back - 1)) / @as(f32, @floatFromInt(steps));
            const angle_back = start_deg + sweep_deg * frac;
            const point_inner = point(cx, cy, inner_radius, angle_back);
            put(&used, path_out, " L {d:.1} {d:.1}", .{ point_inner.x, point_inner.y });
        }
    } else {
        put(&used, path_out, " L {d:.1} {d:.1}", .{ cx, cy });
    }
    put(&used, path_out, " Z", .{});
    if (used > path_out.len) return null;
    return path_out[0..used];
}

fn point(cx: f32, cy: f32, radius: f32, deg: f32) struct { x: f32, y: f32 } {
    const rad = deg * std.math.pi / 180.0;
    return .{ .x = cx + radius * @cos(rad), .y = cy + radius * @sin(rad) };
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

test "pie slices sum to the full circle" {
    const slices = [_]Slice{
        .{ .value = 3, .fill = theme.chart_1 },
        .{ .value = 1, .fill = theme.chart_2 },
    };
    const chart = PieChart.init(&slices).size(200);
    var scratch: [8192]u8 = undefined;
    const svg = chart.buildSvg(&scratch) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(@as(usize, 2), std.mem.count(u8, svg, "<path fill="));
    // The last wedge's outer arc ends back at the top point (100.0, 2.0).
    try std.testing.expect(std.mem.indexOf(u8, svg, "L 100.0 2.0") != null);
    try std.testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try std.testing.expect(std.mem.endsWith(u8, svg, "</svg>"));
}

test "donut keeps an inner arc" {
    const slices = [_]Slice{
        .{ .value = 1, .fill = theme.chart_1 },
        .{ .value = 1, .fill = theme.chart_2 },
    };
    const chart = PieChart.init(&slices).size(200).innerRadius(60);
    var scratch: [8192]u8 = undefined;
    const svg = chart.buildSvg(&scratch) orelse return error.TestUnexpectedResult;
    // The inner arc passes through the right side point (cx + 60, cy).
    try std.testing.expect(std.mem.indexOf(u8, svg, "L 160.0 100.0") != null);
}

test "empty and zero-total input" {
    var scratch: [8192]u8 = undefined;
    const empty_slices = [_]Slice{};
    try std.testing.expect(PieChart.init(&empty_slices).buildSvg(&scratch) == null);
    const zero_slices = [_]Slice{.{ .value = 0, .fill = theme.chart_1 }};
    try std.testing.expect(PieChart.init(&zero_slices).buildSvg(&scratch) == null);
}
