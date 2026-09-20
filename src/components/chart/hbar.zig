//! HBar — horizontal bars (ECharts' yAxis category bars, Recharts'
//! layout="vertical" BarChart).

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const HBar = struct {
    values: []const f32 = &.{},
    fills: []const zui.Color = &.{},
    svg_width: f32 = 560,
    svg_height: f32 = 260,
    row_gap: f32 = 6,
    top_pad: f32 = 6,
    bottom_pad: f32 = 6,
    left_pad: f32 = 6,

    pub fn init(values: []const f32) HBar {
        return .{ .values = values };
    }

    pub fn size(self: HBar, width: f32, height: f32) HBar {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn paletteFor(self: HBar, colors: []const zui.Color) HBar {
        var copy = self;
        copy.fills = colors;
        return copy;
    }

    pub fn buildSvg(self: HBar, out: []u8) ?[]const u8 {
        const n = self.values.len;
        if (n == 0) return null;

        var peak: f32 = 0;
        for (self.values) |value| peak = @max(peak, value);
        if (peak <= 0) return null;

        const rows_f: f32 = @floatFromInt(n);
        const row_h = (self.svg_height - 2 * self.top_pad - self.row_gap * (rows_f - 1)) / rows_f;
        const usable_w = self.svg_width - 2 * self.left_pad;

        var hex_buf: [9]u8 = undefined;
        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        var index: usize = 0;
        while (index < n) : (index += 1) {
            const y = self.top_pad + @as(f32, @floatFromInt(index)) * (row_h + self.row_gap);
            const fill = area.hexString(self.colorAt(index), &hex_buf);
            geometry.putRect(&w, self.left_pad, y, self.values[index] / peak * usable_w, row_h, fill, 4);
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    fn colorAt(self: HBar, index: usize) zui.Color {
        if (self.fills.len == 0) return theme.chart_2;
        return self.fills[index % self.fills.len];
    }

    pub fn render(self: HBar, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "hbar rejects unusable data" {
    var scratch: [2048]u8 = undefined;
    try std.testing.expect(HBar.init(&.{}).buildSvg(&scratch) == null);
    try std.testing.expect(HBar.init(&.{ 0, 0 }).buildSvg(&scratch) == null);
}
