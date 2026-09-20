//! TextView — gpui-kit's markdown rendering, block-level subset:
//! headings, bullet/numbered lists, blockquotes, code blocks, paragraphs.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const code_component = @import("code.zig");

pub const Block = union(enum) {
    /// level 1..3 (h1/h2/h3).
    heading: struct { level: u2, text: []const u8 },
    paragraph: []const u8,
    bullet: []const u8,
    /// `marker` is the caller-formatted label ("1.").
    numbered: struct { marker: []const u8, text: []const u8 },
    quote: []const u8,
    code: []const u8,
    divider,
};

/// Headline size for a heading level 1..3 (pure; unit-tested).
pub fn headingSize(level: u2) f32 {
    return switch (level) {
        1 => 24,
        2 => 19,
        else => 16,
    };
}

pub const TextView = struct {
    blocks: []const Block,
    gap_px: f32 = 10,

    pub fn init(blocks: []const Block) TextView {
        return .{ .blocks = blocks };
    }

    pub fn gap(self: TextView, px: f32) TextView {
        var copy = self;
        copy.gap_px = px;
        return copy;
    }

    pub fn render(self: TextView) zui.Element {
        var col = zui.div().flex_col().gap(self.gap_px);
        for (self.blocks) |block| {
            switch (block) {
                .heading => |value| {
                    col = col.child(support.strong(value.text, headingSize(value.level), theme.foreground));
                },
                .paragraph => |text| {
                    col = col.child(support.label(text, 14, theme.body));
                },
                .bullet => |text| {
                    col = col.child(zui.div().flex_row().items_center().gap(8)
                        .child(support.label("·", 14, theme.muted_foreground))
                        .child(support.label(text, 14, theme.body)));
                },
                .numbered => |item| {
                    col = col.child(zui.div().flex_row().items_center().gap(6)
                        .child(support.label(item.marker, 14, theme.muted_foreground))
                        .child(support.label(item.text, 14, theme.body)));
                },
                .quote => |text| {
                    col = col.child(zui.div().flex_row().items_center().gap(10)
                        .child(zui.div().w(3).rounded_full().bg(theme.ring))
                        .child(support.label(text, 14, theme.muted_foreground)));
                },
                .code => |text| {
                    col = col.child(code_component.Code.init(text).asBlock().render());
                },
                .divider => col = col.child(zui.div().w_full().h(1).bg(theme.border)),
            }
        }
        return col;
    }
};

test "heading sizes" {
    try std.testing.expectEqual(@as(f32, 24), headingSize(1));
    try std.testing.expectEqual(@as(f32, 16), headingSize(3));
}
