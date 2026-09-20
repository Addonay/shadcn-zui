//! Candlestick — OHLC candles (ECharts/finance charts).

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const Candle = struct {
    open: f32,
    high: f32,
    low: f32,
    close: f32,
};

/// Up (close >= open) or down (pure).
pub fn isUp(candle: Candle) bool {
    return candle.close >= candle.open;
}

/// Wick top/bottom pixel range within a value span (pure; unit-tested).
pub fn wickSpan(candle: Candle, top: f32, bottom: f32, domain: f32) struct { f32, f32 } {
    const high_y = bottom - (candle.high / domain) * (bottom - top);
    const low_y = bottom - (candle.low / domain) * (bottom - top);
    return .{ high_y, low_y };
}

/// Body top/bottom pixel range (pure; unit-tested).
pub fn bodySpan(candle: Candle, top: f32, bottom: f32, domain: f32) struct { f32, f32 } {
    const body_top_y = bottom - (@max(candle.open, candle.close) / domain) * (bottom - top);
    const body_bottom_y = bottom - (@min(candle.open, candle.close) / domain) * (bottom - top);
    return .{ body_top_y, body_bottom_y };
}

pub const Candlestick = struct {
    candles: []const Candle = &.{},
    svg_width: f32 = 560,
    svg_height: f32 = 280,
    up: zui.Color = theme.success,
    down: zui.Color = theme.destructive,
    wick_color: zui.Color = theme.muted_foreground,
    candle_gap: f32 = 6,
    candle_width_frac: f32 = 0.6,
    top_pad: f32 = 10,
    bottom_pad: f32 = 10,

    pub fn init(candles: []const Candle) Candlestick {
        return .{ .candles = candles };
    }

    pub fn size(self: Candlestick, width: f32, height: f32) Candlestick {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn colors(self: Candlestick, up: zui.Color, down: zui.Color) Candlestick {
        var copy = self;
        copy.up = up;
        copy.down = down;
        return copy;
    }

    pub fn buildSvg(self: Candlestick, out: []u8) ?[]const u8 {
        const n = self.candles.len;
        if (n == 0) return null;

        var peak: f32 = 0;
        for (self.candles) |candle| peak = @max(peak, candle.high);
        if (peak <= 0) return null;

        const top = self.top_pad;
        const bottom = self.svg_height - self.bottom_pad;
        const slot = (self.svg_width - 2 * self.candle_gap) / @as(f32, @floatFromInt(n));
        const body_w = slot * self.candle_width_frac;

        var up_buf: [9]u8 = undefined;
        var down_buf: [9]u8 = undefined;
        var wick_buf: [9]u8 = undefined;
        const up_fill = area.hexString(self.up, &up_buf);
        const down_fill = area.hexString(self.down, &down_buf);
        const wick = area.hexString(self.wick_color, &wick_buf);

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);

        var index: usize = 0;
        while (index < n) : (index += 1) {
            const candle = self.candles[index];
            const center = self.candle_gap + slot * (@as(f32, @floatFromInt(index)) + 0.5);
            const wick_range = wickSpan(candle, top, bottom, peak);
            const body_range = bodySpan(candle, top, bottom, peak);
            const fill = if (isUp(candle)) up_fill else down_fill;

            geometry.putRect(&w, center - 1, wick_range[0], 2, @max(1, wick_range[1] - wick_range[0]), wick, 1);
            geometry.putRect(&w, center - body_w / 2, body_range[0], body_w, @max(1, body_range[1] - body_range[0]), fill, 2);
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    pub fn render(self: Candlestick, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "up/down classification and spans" {
    const up_candle = Candle{ .open = 10, .high = 20, .low = 5, .close = 15 };
    try std.testing.expect(isUp(up_candle));
    const down_candle = Candle{ .open = 15, .high = 20, .low = 5, .close = 8 };
    try std.testing.expect(!isUp(down_candle));

    const wick = wickSpan(up_candle, 0, 100, 20);
    try std.testing.expectApproxEqAbs(@as(f32, 0), wick[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 75), wick[1], 0.001);
    const body = bodySpan(up_candle, 0, 100, 20);
    try std.testing.expectApproxEqAbs(@as(f32, 25), body[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 50), body[1], 0.001);
}
