//! Heatmap — ECharts' value grid: colored cells by magnitude.

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const Heatmap = struct {
    /// Row-major values: rows x columns cells.
    values: []const f32 = &.{},
    rows: usize = 0,
    columns: usize = 0,
    svg_width: f32 = 420,
    svg_height: f32 = 220,
    cell_gap: f32 = 3,
    /// Low-end color; the high end defaults to the blue chart token.
    low: zui.Color = theme.secondary,
    high: zui.Color = theme.chart_2,

    pub fn init(values: []const f32, rows: usize, columns: usize) Heatmap {
        return .{ .values = values, .rows = rows, .columns = columns };
    }

    pub fn size(self: Heatmap, width: f32, height: f32) Heatmap {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn palette(self: Heatmap, low: zui.Color, high: zui.Color) Heatmap {
        var copy = self;
        copy.low = low;
        copy.high = high;
        return copy;
    }

    /// Interpolated fill for a value fraction 0..1 (pure; unit-tested).
    pub fn blend(self: Heatmap, t: f32) zui.Color {
        const clamped = std.math.clamp(t, 0, 1);
        return .{
            .r = self.low.r + (self.high.r - self.low.r) * clamped,
            .g = self.low.g + (self.high.g - self.low.g) * clamped,
            .b = self.low.b + (self.high.b - self.low.b) * clamped,
            .a = 1,
        };
    }

    pub fn buildSvg(self: Heatmap, out: []u8) ?[]const u8 {
        if (self.rows == 0 or self.columns == 0) return null;
        if (self.values.len < self.rows * self.columns) return null;

        var peak: f32 = 0;
        for (self.values[0 .. self.rows * self.columns]) |value| peak = @max(peak, value);
        if (peak <= 0) return null;

        const columns_f: f32 = @floatFromInt(self.columns);
        const rows_f: f32 = @floatFromInt(self.rows);
        const cell_w = (self.svg_width - self.cell_gap * (columns_f - 1)) / columns_f;
        const cell_h = (self.svg_height - self.cell_gap * (rows_f - 1)) / rows_f;

        var hex_buf: [9]u8 = undefined;
        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        var r: usize = 0;
        while (r < self.rows) : (r += 1) {
            var c: usize = 0;
            while (c < self.columns) : (c += 1) {
                const value = self.values[r * self.columns + c];
                const fill = area.hexString(self.blend(value / peak), &hex_buf);
                const x = @as(f32, @floatFromInt(c)) * (cell_w + self.cell_gap);
                const y = @as(f32, @floatFromInt(r)) * (cell_h + self.cell_gap);
                geometry.putRect(&w, x, y, cell_w, cell_h, fill, 4);
            }
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    pub fn render(self: Heatmap, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "blend interpolates endpoints" {
    var heat = Heatmap.init(&.{}, 0, 0);
    try std.testing.expectApproxEqAbs(heat.low.r, heat.blend(0).r, 0.001);
    try std.testing.expectApproxEqAbs(heat.high.r, heat.blend(1).r, 0.001);
}

test "heatmap rejects unusable data" {
    const chart = Heatmap.init(&.{ 1, 2 }, 2, 2);
    var scratch: [4096]u8 = undefined;
    try std.testing.expect(chart.buildSvg(&scratch) == null);
}
