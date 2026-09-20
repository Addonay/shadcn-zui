//! Shared geometry + writing helpers for the chart family (pure, tested).

const std = @import("std");

/// Buffer-backed, non-allocating SVG writer with overflow tracking.
pub const Writer = struct {
    buffer: []u8,
    len: usize = 0,
    overflow: bool = false,

    pub fn append(self: *Writer, bytes: []const u8) void {
        if (self.overflow) return;
        const end = self.len + bytes.len;
        if (end > self.buffer.len) {
            self.overflow = true;
            return;
        }
        @memcpy(self.buffer[self.len..end], bytes);
        self.len = end;
    }

    pub fn print(self: *Writer, comptime format: []const u8, args: anytype) void {
        if (self.overflow) return;
        const text = std.fmt.bufPrint(self.buffer[self.len..], format, args) catch {
            self.overflow = true;
            return;
        };
        self.len += text.len;
    }

    pub fn slice(self: *const Writer) ?[]const u8 {
        if (self.overflow) return null;
        return self.buffer[0..self.len];
    }
};

pub fn openSvg(w: *Writer, width: f32, height: f32) void {
    w.print("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{d}\" height=\"{d:.1}\" viewBox=\"0 0 {d} {d:.1}\">", .{ width, height, width, height });
}

pub fn closeSvg(w: *Writer) void {
    w.append("</svg>");
}

pub fn putRect(w: *Writer, x: f32, y: f32, width: f32, height: f32, fill: []const u8, radius: f32) void {
    w.print("<rect x=\"{d:.1}\" y=\"{d:.1}\" width=\"{d:.1}\" height=\"{d:.1}\" rx=\"{d:.1}\" fill=\"{s}\"/>", .{ x, y, width, height, radius, fill });
}

pub fn putCircle(w: *Writer, cx: f32, cy: f32, radius: f32, fill: []const u8) void {
    w.print("<circle cx=\"{d:.1}\" cy=\"{d:.1}\" r=\"{d:.1}\" fill=\"{s}\"/>", .{ cx, cy, radius, fill });
}

pub fn putPath(w: *Writer, path: []const u8, fill: []const u8, stroke: []const u8, stroke_px: f32) void {
    w.print("<path d=\"{s}\" fill=\"{s}\" stroke=\"{s}\" stroke-width=\"{d:.1}\"/>", .{ path, fill, stroke, stroke_px });
}

/// Point on a circle; degrees are clockwise from 12 o'clock when used with
/// `polarPoint` (pure; unit-tested).
pub fn polarPoint(cx: f32, cy: f32, radius: f32, deg: f32) struct { x: f32, y: f32 } {
    const rad = deg * std.math.pi / 180.0;
    return .{ .x = cx + radius * @sin(rad), .y = cy - radius * @cos(rad) };
}

/// Map a value into a pixel span (pure; unit-tested).
pub fn map(value: f32, from_min: f32, from_max: f32, to_min: f32, to_max: f32) f32 {
    const span = from_max - from_min;
    if (span <= 0) return to_min;
    const t = (value - from_min) / span;
    return to_min + t * (to_max - to_min);
}

test "polar point lands on the axes" {
    const top = polarPoint(100, 100, 50, 0);
    try std.testing.expectApproxEqAbs(@as(f32, 100), top.x, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 50), top.y, 0.001);
    const right = polarPoint(100, 100, 50, 90);
    try std.testing.expectApproxEqAbs(@as(f32, 150), right.x, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 100), right.y, 0.001);
}

test "map spans" {
    try std.testing.expectApproxEqAbs(@as(f32, 50), map(0.5, 0, 1, 0, 100), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0), map(0, 0, 10, 0, 100), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 20), map(5, 0, 5, 10, 20), 0.001);
}
