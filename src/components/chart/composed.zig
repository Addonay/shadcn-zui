//! Composed — bars with a line overlay (Recharts' ComposedChart).

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const Composed = struct {
    bar_values: []const f32 = &.{},
    line_values: []const f32 = &.{},
    bar_fill: zui.Color = theme.chart_2,
    line_stroke: zui.Color = theme.foreground,
    svg_width: f32 = 1200,
    svg_height: f32 = 260,
    grid_step: f32 = 250,
    bar_gap: f32 = 12,
    top_pad: f32 = 8,
    bottom_pad: f32 = 8,

    pub fn init(bar_values: []const f32, line_values: []const f32) Composed {
        return .{ .bar_values = bar_values, .line_values = line_values };
    }

    pub fn size(self: Composed, width: f32, height: f32) Composed {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn gridStep(self: Composed, step: f32) Composed {
        var copy = self;
        copy.grid_step = step;
        return copy;
    }

    pub fn buildSvg(self: Composed, out: []u8) ?[]const u8 {
        const bar_count = self.bar_values.len;
        const line_count = self.line_values.len;
        if (bar_count == 0 or line_count < 2) return null;

        var peak: f32 = 0;
        for (self.bar_values) |value| peak = @max(peak, value);
        for (self.line_values) |value| peak = @max(peak, value);
        const domain = area.niceDomain(peak, self.grid_step);

        const top = self.top_pad;
        const bottom = self.svg_height - self.bottom_pad;
        const usable = self.svg_width - 2 * self.bar_gap;

        var bar_buf: [9]u8 = undefined;
        var line_buf: [9]u8 = undefined;
        const bar_fill = area.hexString(self.bar_fill, &bar_buf);
        const line_stroke = area.hexString(self.line_stroke, &line_buf);

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        // Bars.
        const slot = usable / @as(f32, @floatFromInt(bar_count));
        const bar_w = slot * 0.6;
        var index: usize = 0;
        while (index < bar_count) : (index += 1) {
            const center = self.bar_gap + slot * (@as(f32, @floatFromInt(index)) + 0.5);
            const top_y = bottom - (self.bar_values[index] / domain) * (bottom - top);
            geometry.putRect(&w, center - bar_w / 2, top_y, bar_w, @max(1, bottom - top_y), bar_fill, 3);
        }

        // Line across the same domain (x spans the full usable width).
        const line_dx = usable / @as(f32, @floatFromInt(line_count - 1));
        w.print("<path d=\"M {d:.1} {d:.1}", .{
            self.bar_gap,
            bottom - (self.line_values[0] / domain) * (bottom - top),
        });
        var line_index: usize = 1;
        while (line_index < line_count) : (line_index += 1) {
            const x = self.bar_gap + @as(f32, @floatFromInt(line_index)) * line_dx;
            const y = bottom - (self.line_values[line_index] / domain) * (bottom - top);
            w.print(" L {d:.1} {d:.1}", .{ x, y });
        }
        w.print("\" fill=\"none\" stroke=\"{s}\" stroke-width=\"2\"/>", .{line_stroke});
        geometry.closeSvg(&w);
        return w.slice();
    }

    pub fn render(self: Composed, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "composed rejects unusable data" {
    var scratch: [4096]u8 = undefined;
    try std.testing.expect(Composed.init(&.{}, &.{}).buildSvg(&scratch) == null);
    try std.testing.expect(Composed.init(&.{ 1, 2 }, &.{1}).buildSvg(&scratch) == null);
}
