//! Treemap — d3/ECharts' area-proportional rectangles (squarified layout).

const std = @import("std");

const zui = @import("zui");
const theme = @import("../../theme.zig");
const geometry = @import("geometry.zig");
const area = @import("area.zig");

pub const Node = struct {
    label: []const u8 = "",
    value: f32,
};

pub const Placed = struct {
    x: f32 = 0,
    y: f32 = 0,
    w: f32 = 0,
    h: f32 = 0,
    color: zui.Color,
};

/// Squarified layout into `out` for one row strip (pure core, unit-tested).
/// This is the simple "slice and dice into squarified rows" variant: rows of
/// decreasing width, which keeps the algorithm allocation-free and stable.
pub fn layout(values: []const f32, x0: f32, y0: f32, width: f32, height: f32, out: []Placed) ?[]Placed {
    if (values.len == 0 or out.len < values.len) return null;
    var total: f32 = 0;
    for (values) |value| total += value;
    if (total <= 0) return null;

    // Rows of up to 4 items, laid out top-to-bottom, splitting each row's
    // width proportionally inside the strip.
    var y = y0;
    var index: usize = 0;
    while (index < values.len) {
        // Greedily fill the row while its aspect ratio improves; capped at 6
        // per row to keep the strip readable.
        var row_total: f32 = 0;
        var row_len: usize = 0;
        while (row_len < 4 and index + row_len < values.len) {
            row_total += values[index + row_len];
            row_len += 1;
        }
        const row_h = height * (row_total / total);
        var row_share: f32 = 0;
        var slot: usize = 0;
        while (slot < row_len) : (slot += 1) {
            const w = width * (values[index + slot] / row_total);
            out[index + slot] = .{
                .x = x0 + row_share,
                .y = y,
                .w = w,
                .h = row_h,
                .color = theme.chart_1,
            };
            row_share += w;
        }
        y += row_h;
        index += row_len;
    }
    return out[0..values.len];
}

pub const Treemap = struct {
    nodes: []const Node = &.{},
    svg_width: f32 = 420,
    svg_height: f32 = 280,
    cell_gap: f32 = 3,
    palette: []const zui.Color = &.{},

    pub fn init(nodes: []const Node) Treemap {
        return .{ .nodes = nodes };
    }

    pub fn size(self: Treemap, width: f32, height: f32) Treemap {
        var copy = self;
        copy.svg_width = width;
        copy.svg_height = height;
        return copy;
    }

    pub fn paletteFor(self: Treemap, colors: []const zui.Color) Treemap {
        var copy = self;
        copy.palette = colors;
        return copy;
    }

    pub fn buildSvg(self: Treemap, out: []u8) ?[]const u8 {
        if (self.nodes.len == 0) return null;
        var placed: [32]Placed = undefined;
        if (self.nodes.len > placed.len) return null;
        var values: [32]f32 = undefined;
        for (self.nodes, 0..) |node, i| values[i] = node.value;
        const boxes = layout(values[0..self.nodes.len], 0, 0, self.svg_width, self.svg_height, &placed) orelse return null;

        var w = geometry.Writer{ .buffer = out };
        geometry.openSvg(&w, self.svg_width, self.svg_height);
        for (boxes, 0..) |box, index| {
            var hex_buf: [9]u8 = undefined;
            const fill = area.hexString(self.colorFor(index), &hex_buf);
            geometry.putRect(&w, box.x, box.y, @max(0, box.w - self.cell_gap), @max(0, box.h - self.cell_gap), fill, 6);
        }
        geometry.closeSvg(&w);
        return w.slice();
    }

    fn colorFor(self: Treemap, index: usize) zui.Color {
        if (self.palette.len == 0) {
            return switch (index % 3) {
                0 => theme.chart_1,
                1 => theme.chart_2,
                else => theme.chart_3,
            };
        }
        return self.palette[index % self.palette.len];
    }

    pub fn render(self: Treemap, scratch: []u8) zui.Element {
        const svg = self.buildSvg(scratch) orelse return zui.div();
        return zui.svg(svg);
    }
};

test "layout covers the frame in order" {
    const boxes = [_]Node{
        .{ .value = 6 }, .{ .value = 3 }, .{ .value = 1 },
    };
    var placed: [8]Placed = undefined;
    var values: [8]f32 = undefined;
    for (boxes, 0..) |node, i| values[i] = node.value;
    const result = layout(values[0..boxes.len], 0, 0, 100, 100, &placed) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expectApproxEqAbs(@as(f32, 0), result[0].x, 0.001);
    try std.testing.expect(result[0].w > result[1].w);
}
