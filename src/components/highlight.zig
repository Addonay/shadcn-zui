//! Highlight — Mantine/TanStack-Highlight's marked-substring text.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Slice = struct {
    text: []const u8,
    marked: bool,
};

/// Split `text` at the first case-insensitive occurrence of `needle`
/// into up to three slices borrowing `text` (pure; unit-tested).
pub fn split(text: []const u8, needle: []const u8) [3]Slice {
    var result = [3]Slice{
        .{ .text = text, .marked = false },
        .{ .text = "", .marked = false },
        .{ .text = "", .marked = false },
    };
    if (needle.len == 0 or needle.len > text.len) return result;

    // Case-insensitive first match.
    var index: usize = 0;
    outer: while (index + needle.len <= text.len) : (index += 1) {
        var offset: usize = 0;
        while (offset < needle.len) : (offset += 1) {
            const a = std.ascii.toLower(text[index + offset]);
            const b = std.ascii.toLower(needle[offset]);
            if (a != b) continue :outer;
        }
        result[0] = .{ .text = text[0..index], .marked = false };
        result[1] = .{ .text = text[index .. index + needle.len], .marked = true };
        result[2] = .{ .text = text[index + needle.len ..], .marked = false };
        return result;
    }
    return result;
}

pub const Highlight = struct {
    text: []const u8,
    needle_value: []const u8 = "",
    marked_bg_value: ?zui.Color = null,

    pub fn init(text: []const u8) Highlight {
        return .{ .text = text };
    }

    /// The substring to highlight (case-insensitive).
    pub fn needle(self: Highlight, value: []const u8) Highlight {
        var copy = self;
        copy.needle_value = value;
        return copy;
    }

    /// Background of the marked substring.
    pub fn markColor(self: Highlight, color: zui.Color) Highlight {
        var copy = self;
        copy.marked_bg_value = color;
        return copy;
    }

    pub fn render(self: Highlight) zui.Element {
        const parts = split(self.text, self.needle_value);
        var row = zui.div().flex_row().flex_wrap().gap(0);
        for (parts) |part| {
            if (part.marked) {
                row = row.child(zui.div().px(2).rounded(4)
                    .bg(self.marked_bg_value orelse theme.accent)
                    .child(support.label(part.text, 14, theme.foreground)));
            } else if (part.text.len > 0) {
                row = row.child(support.label(part.text, 14, theme.body));
            }
        }
        return row;
    }
};

const std = @import("std");

test "split marks the first case-insensitive match" {
    const slices = split("Install the shadcn-UI package", "shadcn-ui");
    try std.testing.expectEqualStrings("Install the ", slices[0].text);
    try std.testing.expect(slices[1].marked);
    try std.testing.expectEqualStrings(" package", slices[2].text);
}

test "split handles misses and empty needles" {
    const miss = split("abc", "zzz");
    try std.testing.expect(!miss[1].marked);
    try std.testing.expectEqualStrings("abc", miss[0].text);
    const empty = split("abc", "");
    try std.testing.expect(!empty[1].marked);
}
