//! BoxPlot — five-number summaries with whiskers (d3/ECharts boxplot).
//!
//! Callers pass precomputed summaries (like `Candle` for OHLC); statistics
//! over raw samples are out of scope for the SVG builder.

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

/// Five-number summary plus optional outliers (pure data).
pub const Box = struct {
    min: f32,
    q1: f32,
    median: f32,
    q3: f32,
    max: f32,
    outliers: []const f32 = &.{},
};

/// Map a value in [lo, hi] to a pixel y in [bottom, top] (pure).
pub fn yOf(value: f32, lo: f32, hi: f32, top: f32, bottom: f32) f32 {
    return geometry.map(value, lo, hi, bottom, top);
}

/// Box top/bottom pixel range: q3 maps above q1 (pure; unit-tested).
pub fn boxSpan(box: Box, lo: f32, hi: f32, top: f32, bottom: f32) struct { f32, f32 } {
    return .{ yOf(box.q3, lo, hi, top, bottom), yOf(box.q1, lo, hi, top, bottom) };
}

/// Whisker top/bottom pixel range: max maps above min (pure; unit-tested).
pub fn whiskerSpan(box: Box, lo: f32, hi: f32, top: f32, bottom: f32) struct { f32, f32 } {
    return .{ yOf(box.max, lo, hi, top, bottom), yOf(box.min, lo, hi, top, bottom) };
}

/// Data domain over boxes and their outliers (pure; unit-tested).
/// Returns null when there is nothing to scale (no boxes or zero span).
pub fn domain(boxes: []const Box) ?struct { lo: f32, hi: f32 } {
    if (boxes.len == 0) return null;
    var lo: f32 = boxes[0].min;
    var hi: f32 = boxes[0].max;
    for (boxes) |box| {
        lo = @min(lo, box.min);
        hi = @max(hi, box.max);
        for (box.outliers) |out| {
            lo = @min(lo, out);
            hi = @max(hi, out);
        }
    }
    if (!(hi > lo)) return null;
    return .{ .lo = lo, .hi = hi };
}

pub const BoxPlot = struct {
    boxes: []const Box = &.{},
    svg_width: f32 = 560,
    svg_height: f32 = 280,
    fill: zui.Color = theme.chart_1,
    median_color: zui.Color = theme.foreground,
    whisker_color: zui.Color = theme.muted_foreground,
    outlier_color: zui.Color = theme.chart_2,
    box_gap: f32 = 8,
    box_width_frac: f32 = 0.55,
    outlier_px: f32 = 3,
    top_pad: f32 = 10,
    bottom_pad: f32 = 10,

    pub fn init(boxes: []const Box) BoxPlot {
        return .{ .boxes = boxes };
    }

    pub fn size(self: BoxPlot, width: f32, height: f32) BoxPlot {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn buildSvg(self: BoxPlot, out: []u8) ?[]const u8 {
        const n = self.boxes.len;
        if (n == 0) return null;
        const dom = domain(self.boxes) orelse return null;

        const top = self.top_pad;
        const bottom = self.svg_height - self.bottom_pad;
        const slot = (self.svg_width - 2 * self.box_gap) / @as(f32, @floatFromInt(n));
        const box_w = slot * self.box_width_frac;
        const cap_w = box_w * 0.6;

        var fill_buf: [9]u8 = undefined;
        var median_buf: [9]u8 = undefined;
        var whisker_buf: [9]u8 = undefined;
        var outlier_buf: [9]u8 = undefined;
        const fill = area.hexString(self.fill, &fill_buf);
        const median_fill = area.hexString(self.median_color, &median_buf);
        const whisker = area.hexString(self.whisker_color, &whisker_buf);
        const outlier_fill = area.hexString(self.outlier_color, &outlier_buf);

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        var index: usize = 0;
        while (index < n) : (index += 1) {
            const box = self.boxes[index];
            const center = self.box_gap + slot * (@as(f32, @floatFromInt(index)) + 0.5);
            const whiskers = whiskerSpan(box, dom.lo, dom.hi, top, bottom);
            const span = boxSpan(box, dom.lo, dom.hi, top, bottom);
            const median_y = yOf(box.median, dom.lo, dom.hi, top, bottom);

            // Whisker stem + caps.
            geometry.putRect(&w, center - 1, whiskers[0], 2, @max(1, whiskers[1] - whiskers[0]), whisker, 1);
            geometry.putRect(&w, center - cap_w / 2, whiskers[0] - 1, cap_w, 2, whisker, 1);
            geometry.putRect(&w, center - cap_w / 2, whiskers[1] - 1, cap_w, 2, whisker, 1);
            // Box + median line.
            geometry.putRect(&w, center - box_w / 2, span[0], box_w, @max(1, span[1] - span[0]), fill, 2);
            geometry.putRect(&w, center - box_w / 2, median_y - 1, box_w, 2, median_fill, 1);
            // Outliers.
            for (box.outliers) |outlier| {
                geometry.putCircle(&w, center, yOf(outlier, dom.lo, dom.hi, top, bottom), self.outlier_px, outlier_fill);
            }
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    pub fn render(self: BoxPlot, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "box and whisker spans order top before bottom" {
    const box = Box{ .min = 5, .q1 = 20, .median = 35, .q3 = 55, .max = 90 };
    const span = boxSpan(box, 0, 100, 0, 200);
    try std.testing.expect(span[0] < span[1]);
    try std.testing.expectApproxEqAbs(@as(f32, 90), span[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 160), span[1], 0.001);
    const whiskers = whiskerSpan(box, 0, 100, 0, 200);
    try std.testing.expect(whiskers[0] < whiskers[1]);
    try std.testing.expectApproxEqAbs(yOf(box.median, 0, 100, 0, 200), @as(f32, 130), 0.001);
}

test "domain covers outliers and rejects empty input" {
    try std.testing.expect(domain(&.{}) == null);
    const outs = [_]f32{120};
    const boxes = [_]Box{
        .{ .min = 10, .q1 = 20, .median = 30, .q3 = 40, .max = 60, .outliers = outs[0..] },
        .{ .min = 5, .q1 = 15, .median = 25, .q3 = 35, .max = 50 },
    };
    const dom = domain(boxes[0..]).?;
    try std.testing.expectApproxEqAbs(@as(f32, 5), dom.lo, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 120), dom.hi, 0.001);
}

test "degenerate domain builds nothing" {
    const boxes = [_]Box{.{ .min = 10, .q1 = 10, .median = 10, .q3 = 10, .max = 10 }};
    const chart = BoxPlot.init(boxes[0..]);
    var buf: [4096]u8 = undefined;
    try std.testing.expect(chart.buildSvg(&buf) == null);
}
