//! GaugeChart — ECharts' value gauge as a 270-degree arc.

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const sweep_deg: f32 = 270;
pub const start_deg: f32 = -135;

pub const GaugeChart = struct {
    /// Fraction 0..1 (clamped).
    value: f32 = 0,
    fill: zui.Color = theme.chart_2,
    track: zui.Color = theme.secondary,
    svg_width: f32 = 180,
    stroke_px: f32 = 14,

    pub fn init(value: f32) GaugeChart {
        return .{ .value = value };
    }

    pub fn size(self: GaugeChart, px: f32) GaugeChart {
        var copy = self;
        copy.svg_width = px;
        return copy;
    }

    pub fn color(self: GaugeChart, value: zui.Color) GaugeChart {
        var copy = self;
        copy.fill = value;
        return copy;
    }

    pub fn stroke(self: GaugeChart, px: f32) GaugeChart {
        var copy = self;
        copy.stroke_px = px;
        return copy;
    }

    pub fn buildSvg(self: GaugeChart, out: []u8) ?[]const u8 {
        var fill_buf: [9]u8 = undefined;
        var track_buf: [9]u8 = undefined;
        var value_path_buf: [96]u8 = undefined;
        const fill = area.hexString(self.fill, &fill_buf);
        const track = area.hexString(self.track, &track_buf);

        const center = self.svg_width / 2;
        const radius = center - self.stroke_px;
        const clamped = std.math.clamp(self.value, 0, 1);

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_width);

        const track_path = arcPath(start_deg, sweep_deg, center, center, radius, &value_path_buf);
        w.append("<path d=\"");
        w.append(track_path);
        w.print("\" stroke=\"{s}\" stroke-width=\"{d:.1}\" stroke-linecap=\"round\" fill=\"none\"/>", .{
            track, self.stroke_px,
        });
        const value_path = arcPath(start_deg, sweep_deg * clamped, center, center, radius, &value_path_buf);
        w.append("<path d=\"");
        w.append(value_path);
        w.print("\" stroke=\"{s}\" stroke-width=\"{d:.1}\" stroke-linecap=\"round\" fill=\"none\"/>", .{
            fill, self.stroke_px,
        });
        geometry.closeSvg(&w);
        return w.slice();
    }

    pub fn render(self: GaugeChart, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

/// Arc path with SVG arc flags into a caller buffer (pure given the buffer).
pub fn arcPath(from_deg: f32, span_deg: f32, cx: f32, cy: f32, radius: f32, buf: []u8) []const u8 {
    const start = geometry.polarPoint(cx, cy, radius, from_deg);
    const end = geometry.polarPoint(cx, cy, radius, from_deg + span_deg);
    const large: u8 = if (span_deg > 180) 1 else 0;
    return std.fmt.bufPrint(buf, "M {d:.1} {d:.1} A {d:.1} {d:.1} 0 {d} 1 {d:.1} {d:.1}", .{
        start.x, start.y, radius, radius, large, end.x, end.y,
    }) catch "";
}

test "arc path shape" {
    var buf: [96]u8 = undefined;
    const path = arcPath(0, 180, 100, 100, 50, &buf);
    try std.testing.expect(std.mem.startsWith(u8, path, "M "));
    try std.testing.expect(std.mem.indexOf(u8, path, " A ") != null);
}

test "gauge rejects nothing for clamped values" {
    var scratch: [2048]u8 = undefined;
    const chart = GaugeChart.init(0.7);
    try std.testing.expect(chart.buildSvg(&scratch) != null);
}
