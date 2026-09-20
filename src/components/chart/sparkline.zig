//! Sparkline — a compact line/area with no grid or axes.

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const Sparkline = struct {
    values: []const f32 = &.{},
    stroke: zui.Color = theme.chart_2,
    filled: bool = true,
    svg_width: f32 = 120,
    svg_height: f32 = 36,
    top_pad: f32 = 2,
    bottom_pad: f32 = 2,

    pub fn init(values: []const f32) Sparkline {
        return .{ .values = values };
    }

    pub fn size(self: Sparkline, width: f32, height: f32) Sparkline {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn color(self: Sparkline, value: zui.Color) Sparkline {
        var copy = self;
        copy.stroke = value;
        return copy;
    }

    pub fn asLine(self: Sparkline) Sparkline {
        var copy = self;
        copy.filled = false;
        return copy;
    }

    pub fn buildSvg(self: Sparkline, out: []u8) ?[]const u8 {
        const n = self.values.len;
        if (n < 2) return null;

        var peak: f32 = 0;
        for (self.values) |value| peak = @max(peak, value);
        if (peak <= 0) return null;

        var stroke_buf: [9]u8 = undefined;
        var fill_buf: [9]u8 = undefined;
        const stroke = area.hexString(self.stroke, &stroke_buf);
        const fill = area.hexString(self.stroke, &fill_buf);

        const top = self.top_pad;
        const bottom = self.svg_height - self.bottom_pad;
        const dx = (self.svg_width - 2) / @as(f32, @floatFromInt(n - 1));

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        // Path: straight segments (fine at this size, keeps the SVG tiny).
        w.print("<path d=\"M 1 {d:.1}", .{bottom - (self.values[0] / peak) * (bottom - top)});
        var i: usize = 1;
        while (i < n) : (i += 1) {
            const x = 1 + @as(f32, @floatFromInt(i)) * dx;
            const y = bottom - (self.values[i] / peak) * (bottom - top);
            w.print(" L {d:.1} {d:.1}", .{ x, y });
        }
        if (self.filled) {
            w.print(" L {d:.1} {d:.1} L 1 {d:.1} Z\" fill=\"{s}\" opacity=\"0.25\" stroke=\"{s}\" stroke-width=\"1.5\"/>", .{
                self.svg_width - 1,
                bottom,
                bottom,
                fill,
                stroke,
            });
        } else {
            w.print("\" fill=\"none\" stroke=\"{s}\" stroke-width=\"1.5\"/>", .{stroke});
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    pub fn render(self: Sparkline, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "sparkline rejects unusable data" {
    const chart = Sparkline.init(&.{42});
    var scratch: [1024]u8 = undefined;
    try std.testing.expect(chart.buildSvg(&scratch) == null);
}
