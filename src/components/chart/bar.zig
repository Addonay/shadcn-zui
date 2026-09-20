//! BarChart — grouped bars rendered as SVG (same conventions as the area
//! chart): each group holds one bar per series side by side, the y domain
//! is niced to `grid_step` steps, and `buildSvg` writes into a
//! caller-provided scratch buffer that `render` hands to `zui.svg`.

const std = @import("std");

const area = @import("area.zig");
const theme = @import("../../theme.zig");
const zui = @import("zui");

/// One x-axis group: a label plus one value per series.
pub const Group = struct {
    label: []const u8 = "",
    values: []const f32,
};

pub const default_width: f32 = 600;
pub const default_height: f32 = 240;

pub const side_pad: f32 = 8;
pub const top_pad: f32 = 8;
pub const bottom_pad: f32 = 8;
pub const default_group_gap: f32 = 24;
pub const default_bar_gap: f32 = 4;
pub const default_grid_step: f32 = 100;

/// The palette used when the caller passes fewer colors than series.
const fallback_palette = [_]zui.Color{ theme.chart_1, theme.chart_2, theme.chart_3 };

/// Peak of every series across all groups (0 when empty).
pub fn peakValue(groups: []const Group) f32 {
    var peak: f32 = 0;
    for (groups) |group| {
        for (group.values) |value| {
            if (value > peak) peak = value;
        }
    }
    return peak;
}

pub const BarChart = struct {
    groups: []const Group,
    /// One color per series (bar index within a group).
    palette: []const zui.Color = &.{},
    svg_width: f32 = default_width,
    svg_height: f32 = default_height,
    group_gap: f32 = default_group_gap,
    bar_gap: f32 = default_bar_gap,
    grid_step: f32 = default_grid_step,

    pub fn init(groups: []const Group) BarChart {
        return .{ .groups = groups };
    }

    pub fn paletteFor(self: BarChart, list: []const zui.Color) BarChart {
        var copy = self;
        copy.palette = list;
        return copy;
    }

    pub fn size(self: BarChart, width: f32, height: f32) BarChart {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn gridStep(self: BarChart, step: f32) BarChart {
        var copy = self;
        copy.grid_step = step;
        return copy;
    }

    /// Resolved palette for `series_count` bars (pure; unit-tested).
    pub fn resolvedPalette(self: BarChart, series_count: usize, buf: *[3]zui.Color) []const zui.Color {
        if (self.palette.len >= series_count) return self.palette[0..series_count];
        for (0..@min(series_count, 3)) |index| buf[index] = fallback_palette[index];
        return buf[0..@min(series_count, 3)];
    }

    /// Write the SVG into `out`; null when it doesn't fit.
    pub fn buildSvg(self: BarChart, out: []u8) ?[]const u8 {
        var used: usize = 0;

        var series_count: usize = 0;
        for (self.groups) |group| {
            if (group.values.len > series_count) series_count = group.values.len;
        }
        if (self.groups.len == 0 or series_count == 0) return null;

        var palette_buf: [3]zui.Color = undefined;
        const palette = self.resolvedPalette(series_count, &palette_buf);
        const peak = peakValue(self.groups);
        if (peak <= 0) return null;
        const domain = if (self.grid_step > 0) area.niceDomain(peak, self.grid_step) else peak * 1.1;

        const top = top_pad;
        const bottom = self.svg_height - bottom_pad;
        const left = side_pad;
        const right = self.svg_width - side_pad;
        const plot_w = right - left;

        var hex_bufs: [3][9]u8 = undefined;

        put(&used, out, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{d}\" height=\"{d:.1}\" viewBox=\"0 0 {d} {d:.1}\">", .{ self.svg_width, self.svg_height, self.svg_width, self.svg_height });

        if (self.grid_step > 0) {
            var tick = self.grid_step;
            while (tick < domain) : (tick += self.grid_step) {
                const y = bottom - tick / domain * (bottom - top);
                put(&used, out, "<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"#262626\" stroke-width=\"1\"/>", .{ left, y, right, y });
            }
        }

        const group_count: f32 = @floatFromInt(self.groups.len);
        const bars: f32 = @floatFromInt(series_count);
        const group_w = (plot_w - self.group_gap * (group_count - 1)) / group_count;
        const bar_w = (group_w - self.bar_gap * (bars - 1)) / bars;

        for (self.groups, 0..) |group, group_index| {
            const group_x = left + @as(f32, @floatFromInt(group_index)) * (group_w + self.group_gap);
            for (group.values, 0..) |value, series_index| {
                const h = value / domain * (bottom - top);
                const x = group_x + @as(f32, @floatFromInt(series_index)) * (bar_w + self.bar_gap);
                const hex = area.hexString(palette[series_index], &hex_bufs[series_index]);
                put(&used, out, "<rect x=\"{d:.1}\" y=\"{d:.1}\" width=\"{d:.1}\" height=\"{d:.1}\" fill=\"{s}\"/>", .{ x, bottom - h, bar_w, h, hex });
            }
        }

        put(&used, out, "</svg>", .{});
        if (used > out.len) return null;
        return out[0..used];
    }

    pub fn render(self: BarChart, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse "";
        return zui.svg(svg).w_full().h(self.svg_height);
    }
};

fn put(used: *usize, out: []u8, comptime format: []const u8, args: anytype) void {
    if (used.* >= out.len) {
        used.* = out.len + 1;
        return;
    }
    const text = std.fmt.bufPrint(out[used.*..], format, args) catch {
        // Overflow: pin `used` past the end so the final length check fails.
        used.* = out.len + 1;
        return;
    };
    used.* += text.len;
}

test "peak across groups" {
    const groups = [_]Group{
        .{ .values = &.{ 120, 40 } },
        .{ .values = &.{ 80, 160 } },
    };
    try std.testing.expectApproxEqAbs(@as(f32, 160), peakValue(&groups), 0.001);
}

test "resolved palette falls back to the chart tokens" {
    const groups = [_]Group{.{ .values = &.{1} }};
    const chart = BarChart.init(&groups);
    var buf: [3]zui.Color = undefined;
    try std.testing.expectEqual(theme.chart_1, chart.resolvedPalette(2, &buf)[0]);
    try std.testing.expectEqual(theme.chart_2, chart.resolvedPalette(2, &buf)[1]);

    const custom = [_]zui.Color{ theme.success, theme.warning };
    const customized = chart.paletteFor(&custom);
    try std.testing.expectEqual(theme.success, customized.resolvedPalette(2, &buf)[0]);
}

test "buildSvg writes one rect per bar" {
    const groups = [_]Group{
        .{ .label = "Jan", .values = &.{ 120, 40 } },
        .{ .label = "Feb", .values = &.{ 80, 160 } },
    };
    const chart = BarChart.init(&groups).gridStep(100);
    var scratch: [8192]u8 = undefined;
    const svg = chart.buildSvg(&scratch) orelse return error.TestUnexpectedResult;
    try std.testing.expect(std.mem.indexOf(u8, svg, "<svg") != null);
    try std.testing.expectEqual(@as(usize, 4), std.mem.count(u8, svg, "<rect"));
}

test "too-small buffer yields null" {
    const groups = [_]Group{.{ .values = &.{120} }};
    const chart = BarChart.init(&groups);
    var tiny: [16]u8 = undefined;
    try std.testing.expect(chart.buildSvg(&tiny) == null);
}
