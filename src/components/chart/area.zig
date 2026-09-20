//! AreaChart — layered area chart rendered as an SVG that zui's `svg()`
//! element rasterizes.
//!
//! Ported from the dashboard reference (`zui/examples/dash/chart.zig`): the
//! curves are natural cubic splines through the raw samples, each band is a
//! closed area filled with a `userSpaceOnUse` linear gradient (nanosvg ignores
//! the `objectBoundingBox` default), and every stroke is drawn on top of the
//! fills.
//!
//! The builder never allocates. `buildSvg` writes into a caller-provided
//! scratch buffer (the dashboard keeps one in app state); `render` builds into
//! that buffer and hands the bytes to `zui.svg`.
//!
//! ```zig
//! var scratch: [16384]u8 = undefined;
//! AreaChart.init(&series).size(1200, 260).render(&scratch)
//! ```
//!
//! When `buildSvg` cannot fit the SVG in the buffer it returns `null`. Callers
//! that need to react to that (log it, enlarge the scratch, fall back to a
//! smaller chart) should call `buildSvg` directly; `render` can only render an
//! empty element in that case.

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");

/// Fixed spline-solver capacity. Series longer than this are truncated to
/// their first `MAX_POINTS` samples (the dashboard holds 91 points).
pub const MAX_POINTS: usize = 256;

/// One band of the chart. `values` are raw (value-space) samples, drawn as an
/// area from the baseline up to the spline, with a stroke on top.
pub const Series = struct {
    values: []const f32,
    /// Curve stroke (the dashboard used near-white `#e8e8e8`).
    stroke: zui.Color,
    /// Gradient stop at the series' own top (its maximum value).
    fill_top: zui.Color,
    /// Gradient stop at the baseline.
    fill_bottom: zui.Color,
};

pub const AreaChart = struct {
    series: []const Series = &.{},
    /// Internal coordinate width; the element stretches to its container.
    svg_width: f32 = 1200,
    svg_height: f32 = 260,
    /// Value-space gridline step; `0` disables gridlines.
    grid_step: f32 = 250,
    grid_color: zui.Color = theme.border,
    top_pad: f32 = 8,
    bottom_pad: f32 = 8,
    side_pad: f32 = 10,

    pub fn init(series: []const Series) AreaChart {
        return .{ .series = series };
    }

    pub fn size(self: AreaChart, width: f32, height: f32) AreaChart {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn gridStep(self: AreaChart, step: f32) AreaChart {
        var copy = self;
        copy.grid_step = step;
        return copy;
    }

    pub fn pad(self: AreaChart, top: f32, bottom: f32, sides: f32) AreaChart {
        var copy = self;
        copy.top_pad = top;
        copy.bottom_pad = bottom;
        copy.side_pad = sides;
        return copy;
    }

    /// Write the SVG into `out`; `null` when the data is unusable (`n < 2`) or
    /// the SVG would not fit.
    pub fn buildSvg(self: AreaChart, out: []u8) ?[]const u8 {
        if (self.series.len == 0) return null;

        // The spline runs over the shortest series so every band spans the
        // same vertex count, capped by the fixed solver arrays.
        var n: usize = MAX_POINTS;
        for (self.series) |series| n = @min(n, series.values.len);
        if (n < 2) return null;

        const top: f32 = self.top_pad;
        const bottom: f32 = self.svg_height - self.bottom_pad;
        const left: f32 = self.side_pad;
        const right: f32 = self.svg_width - self.side_pad;
        const span: f32 = bottom - top;

        var peak: f32 = 0;
        for (self.series) |series| {
            for (series.values[0..n]) |value| {
                if (value > peak) peak = value;
            }
        }
        const domain = niceDomain(peak, self.grid_step);

        const dx = (right - left) / @as(f32, @floatFromInt(n - 1));

        var writer = Writer{ .buffer = out };

        writer.print("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{d}\" height=\"{d:.1}\" viewBox=\"0 0 {d} {d:.1}\">", .{
            self.svg_width,
            self.svg_height,
            self.svg_width,
            self.svg_height,
        });

        // nanosvg treats gradient stops as user-space units, so anchor each
        // band's gradient to that band's own top and the baseline explicitly.
        writer.append("<defs>");
        for (self.series, 0..) |series, i| {
            const series_top = topPixel(series, n, domain, top, bottom);
            const fill_top = colorHex(series.fill_top);
            const fill_bottom = colorHex(series.fill_bottom);
            writer.print("<linearGradient id=\"g{d}\" gradientUnits=\"userSpaceOnUse\" x1=\"0\" y1=\"{d:.1}\" x2=\"0\" y2=\"{d:.1}\">", .{
                i,
                series_top,
                bottom,
            });
            writer.print("<stop offset=\"0\" stop-color=\"{s}\"/>", .{fill_top[0..]});
            writer.print("<stop offset=\"1\" stop-color=\"{s}\"/>", .{fill_bottom[0..]});
            writer.append("</linearGradient>");
        }
        writer.append("</defs>");

        // Horizontal gridlines at each whole step up to and including the top.
        if (self.grid_step > 0) {
            const grid = colorHex(self.grid_color);
            var tick: f32 = self.grid_step;
            while (tick <= domain + 0.0001) : (tick += self.grid_step) {
                const y = bottom - tick / domain * span;
                writer.print("<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"{s}\" stroke-width=\"1\"/>", .{
                    left,
                    y,
                    right,
                    y,
                    grid[0..],
                });
            }
        }

        var model: Pixels = .{};

        // Areas first, in array order, each closed down to the baseline.
        for (self.series, 0..) |series, i| {
            computePixels(series, n, domain, bottom, span, &model);
            writer.append("<path d=\"");
            appendArea(&writer, &model, n, left, dx, bottom);
            writer.print("\" fill=\"url(#g{d})\" stroke=\"none\"/>", .{i});
        }

        // Every stroke on top so both band boundaries stay crisp.
        for (self.series) |series| {
            computePixels(series, n, domain, bottom, span, &model);
            const stroke = colorHex(series.stroke);
            writer.append("<path d=\"");
            appendCurve(&writer, &model, n, left, dx);
            writer.print("\" fill=\"none\" stroke=\"{s}\" stroke-width=\"1.6\"/>", .{stroke[0..]});
        }

        writer.append("</svg>");

        if (writer.overflow) return null;
        return out[0..writer.len];
    }

    /// Build into `scratch` and return the SVG element, stretched to the
    /// container width and `svg_height` tall. The caller owns `scratch` and
    /// must keep it alive for as long as the built element is in use.
    pub fn render(self: AreaChart, scratch: []u8) zui.Element {
        const bytes = self.buildSvg(scratch) orelse {
            // `buildSvg` already reported the failure with `null`; an empty
            // element is the only non-optional result render can return.
            return zui.div().w_full().h(self.svg_height);
        };
        return zui.svg(bytes).w_full().h(self.svg_height);
    }
};

/// Round `peak` up to the next whole `step` (value-space "nice" domain).
/// With `step <= 0` fall back to `peak * 1.1` with a floor of 1.
pub fn niceDomain(peak: f32, step: f32) f32 {
    if (step > 0) {
        const ticks = @ceil(peak / step);
        return @max(step, ticks * step);
    }
    return @max(@as(f32, 1), peak * 1.1);
}

/// Format `c` as an opaque `#rrggbb` string in `buf` and return that slice.
/// Alpha is intentionally ignored: the dashboard's stops are opaque.
pub fn hexString(c: zui.Color, buf: *[9]u8) []const u8 {
    const r = channel(c.r);
    const g = channel(c.g);
    const b = channel(c.b);
    return std.fmt.bufPrint(buf, "#{x:0>2}{x:0>2}{x:0>2}", .{ r, g, b }) catch unreachable;
}

fn channel(value: f32) u8 {
    const clamped = @max(@as(f32, 0), @min(@as(f32, 1), value));
    return @intFromFloat(@round(clamped * 255.0));
}

fn colorHex(c: zui.Color) [9]u8 {
    var buf: [9]u8 = undefined;
    _ = hexString(c, &buf);
    return buf;
}

/// Pixel-space samples plus the natural-spline second derivatives.
const Pixels = struct {
    values: [MAX_POINTS]f64 = undefined,
    second: [MAX_POINTS]f64 = undefined,
};

/// Map raw values into pixel space (`bottom - value/domain * span`) and solve
/// the natural spline for that band.
fn computePixels(series: Series, n: usize, domain: f32, bottom: f32, span: f32, out: *Pixels) void {
    for (series.values[0..n], 0..) |value, i| {
        out.values[i] = @as(f64, bottom) - @as(f64, value) / @as(f64, domain) * @as(f64, span);
    }
    solveNatural(&out.values, &out.second, n);
}

/// The band's topmost pixel row (its maximum value mapped to y).
fn topPixel(series: Series, n: usize, domain: f32, top: f32, bottom: f32) f64 {
    var max_value: f32 = series.values[0];
    for (series.values[0..n]) |value| {
        if (value > max_value) max_value = value;
    }
    return @as(f64, bottom) - @as(f64, max_value) / @as(f64, domain) * @as(f64, bottom - top);
}

/// Natural cubic spline with uniform spacing (h = 1):
///   M[i-1] + 4 M[i] + M[i+1] = 6 (y[i+1] - 2y[i] + y[i-1])
/// with M[0] = M[n-1] = 0. Verbatim port of the dashboard's solver.
fn solveNatural(values: *const [MAX_POINTS]f64, second: *[MAX_POINTS]f64, n: usize) void {
    var b: [MAX_POINTS]f64 = undefined;
    var d: [MAX_POINTS]f64 = undefined;
    b[0] = 1;
    second[0] = 0;
    var i: usize = 1;
    while (i < n - 1) : (i += 1) {
        b[i] = 4;
        d[i] = 6 * (values[i + 1] - 2 * values[i] + values[i - 1]);
    }
    b[n - 1] = 1;
    d[n - 1] = 0;
    i = 1;
    while (i < n) : (i += 1) {
        const m = 1.0 / b[i - 1];
        b[i] -= m;
        d[i] -= m * d[i - 1];
    }
    second[n - 1] = 0;
    i = n - 1;
    while (i > 0) {
        i -= 1;
        second[i] = (d[i] - second[i + 1]) / b[i];
    }
}

/// Append the spline along `model` closed down to `baseline` (an area path).
fn appendArea(writer: *Writer, model: *const Pixels, n: usize, x0: f32, dx: f32, baseline: f32) void {
    // `appendCurve` opens with the move-to, so the area is just the curve plus
    // a close back down to the baseline.
    appendCurve(writer, model, n, x0, dx);
    writer.print("L {d:.1} {d:.1} Z ", .{ x0 + @as(f32, @floatFromInt(n - 1)) * dx, baseline });
}

/// Append just the spline (no fill, no close), for the stroke on top.
fn appendCurve(writer: *Writer, model: *const Pixels, n: usize, x0: f32, dx: f32) void {
    writer.print("M {d:.1} {d:.1} ", .{ x0, model.values[0] });
    var i: usize = 0;
    while (i < n - 1) : (i += 1) {
        const x_a = x0 + @as(f32, @floatFromInt(i)) * dx;
        const x_b = x_a + dx;
        const y_a = model.values[i];
        const y_b = model.values[i + 1];
        const b = (y_b - y_a) - (2 * model.second[i] + model.second[i + 1]) / 6.0;
        const m1 = b + (model.second[i] + model.second[i + 1]) / 2.0;
        writer.print("C {d:.1} {d:.1} {d:.1} {d:.1} {d:.1} {d:.1} ", .{
            x_a + dx / 3.0,
            y_a + b / 3.0,
            x_b - dx / 3.0,
            y_b - m1 / 3.0,
            x_b,
            y_b,
        });
    }
}

/// Grows a byte buffer without an allocator; `overflow` records the first
/// append that didn't fit so `buildSvg` can return `null`.
const Writer = struct {
    buffer: []u8,
    len: usize = 0,
    overflow: bool = false,

    fn append(self: *Writer, bytes: []const u8) void {
        if (self.overflow) return;
        const end = self.len + bytes.len;
        if (end > self.buffer.len) {
            self.overflow = true;
            return;
        }
        @memcpy(self.buffer[self.len..end], bytes);
        self.len = end;
    }

    fn print(self: *Writer, comptime format: []const u8, args: anytype) void {
        if (self.overflow) return;
        const text = std.fmt.bufPrint(self.buffer[self.len..], format, args) catch {
            self.overflow = true;
            return;
        };
        self.len += text.len;
    }
};

test "buildSvg emits svg, gradients, spline curves and gridlines" {
    const a = [_]f32{ 10, 40, 30, 80, 60, 120, 90, 140 };
    const b = [_]f32{ 5, 20, 15, 40, 30, 60, 45, 70 };
    const series = [_]Series{
        .{
            .values = &a,
            .stroke = theme.white,
            .fill_top = theme.muted_foreground,
            .fill_bottom = theme.background,
        },
        .{
            .values = &b,
            .stroke = theme.white,
            .fill_top = theme.faint,
            .fill_bottom = theme.background,
        },
    };
    const chart = AreaChart.init(&series);
    var buf: [16384]u8 = undefined;
    const svg = chart.buildSvg(&buf) orelse return error.BuildFailed;

    try std.testing.expect(std.mem.indexOf(u8, svg, "<svg") != null);
    try std.testing.expect(std.mem.indexOf(u8, svg, "url(#g0)") != null);
    try std.testing.expect(std.mem.indexOf(u8, svg, "url(#g1)") != null);
    try std.testing.expect(std.mem.indexOf(u8, svg, "C ") != null);
    try std.testing.expect(std.mem.indexOf(u8, svg, "<line ") != null);
    try std.testing.expect(std.mem.endsWith(u8, svg, "</svg>"));
}

test "buildSvg returns null when the scratch buffer is too small" {
    const values = [_]f32{ 1, 2, 3, 4 };
    const series = [_]Series{.{
        .values = &values,
        .stroke = theme.white,
        .fill_top = theme.white,
        .fill_bottom = theme.background,
    }};
    const chart = AreaChart.init(&series);
    var tiny: [32]u8 = undefined;
    try std.testing.expect(chart.buildSvg(&tiny) == null);
}

test "buildSvg rejects degenerate series" {
    var buf: [1024]u8 = undefined;

    const none: []const Series = &.{};
    try std.testing.expect(AreaChart.init(none).buildSvg(&buf) == null);

    const one = [_]f32{5};
    const series = [_]Series{.{
        .values = &one,
        .stroke = theme.white,
        .fill_top = theme.white,
        .fill_bottom = theme.background,
    }};
    try std.testing.expect(AreaChart.init(&series).buildSvg(&buf) == null);
}

test "niceDomain rounds up to the next grid step" {
    try std.testing.expectEqual(@as(f32, 1250), niceDomain(1018, 250));
    try std.testing.expectEqual(@as(f32, 250), niceDomain(200, 250));
    try std.testing.expectEqual(@as(f32, 500), niceDomain(251, 250));
    // step <= 0 falls back to a padded raw peak with a floor of 1.
    try std.testing.expectEqual(@as(f32, 1.1), niceDomain(1, 0));
    try std.testing.expectEqual(@as(f32, 1), niceDomain(0, 0));
}

test "hexString emits opaque #rrggbb" {
    var buf: [9]u8 = undefined;
    try std.testing.expectEqualStrings("#121212", hexString(theme.background, &buf));
    try std.testing.expectEqualStrings("#ffffff", hexString(theme.white, &buf));
    try std.testing.expectEqualStrings("#0ddf72", hexString(theme.success, &buf));
}
