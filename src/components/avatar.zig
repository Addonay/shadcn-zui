//! Avatar — shadcn/ui's circular (or square) user chip.
//!
//! Mirrors shadcn's [`Avatar`](https://ui.shadcn.com/docs/components/avatar):
//! a fixed-size frame that shows an image when supplied, otherwise a muted
//! background with the user's initials.
//!
//! ```zig
//! Avatar.init("Jane Doe").size(.md).render()
//! Avatar.init("Jane Doe").image(png_bytes).sizePx(40).shape(.square).render()
//! ```

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");

pub const Size = enum { sm, md, lg, xl };
pub const Shape = enum { circle, square };

/// shadcn's avatar sizes: 24 / 32 / 40 / 48.
pub fn pxFor(size: Size) f32 {
    return switch (size) {
        .sm => 24,
        .md => 32,
        .lg => 40,
        .xl => 48,
    };
}

/// The initials for a display name: the first ASCII-uppercased letter of up to
/// the first two whitespace-separated words, written into `buf`.
///
/// `"john doe"` -> `"JD"`, `"shadcn"` -> `"S"`, `""` -> `""`.
///
/// The returned slice borrows `buf`: keep it alive until paint. Callers that
/// cannot own a buffer should let `Avatar.render` borrow letters from the
/// name itself, or set the letters with `Avatar.letters`.
pub fn initials(name: []const u8, buf: *[2]u8) []const u8 {
    var len: usize = 0;
    var words = std.mem.tokenizeAny(u8, name, " \t\r\n");
    while (words.next()) |word| {
        if (len == 2) break;
        buf[len] = std.ascii.toUpper(word[0]);
        len += 1;
    }
    return buf[0..len];
}

/// Byte indices of the first letters of the first two words of `name`.
/// The returned letters borrow from `name`, so they are safe for zui text
/// (which keeps slices borrowed until paint).
pub fn wordStartIndices(name: []const u8, out: *[2]usize) usize {
    var count: usize = 0;
    var words = std.mem.tokenizeAny(u8, name, " \t\r\n");
    while (words.next()) |word| {
        if (count == 2) break;
        out[count] = @intFromPtr(word.ptr) - @intFromPtr(name.ptr);
        count += 1;
    }
    return count;
}

pub const Avatar = struct {
    name: []const u8,
    image_value: ?[]const u8 = null,
    letters_value: ?[]const u8 = null,
    size_value: Size = .md,
    size_px_value: ?f32 = null,
    shape_value: Shape = .circle,

    pub fn init(name: []const u8) Avatar {
        return .{ .name = name };
    }

    /// Override the fallback text (caller-owned slice, e.g. `initials` output
    /// in a buffer that outlives the frame).
    pub fn letters(self: Avatar, value: []const u8) Avatar {
        var copy = self;
        copy.letters_value = value;
        return copy;
    }

    /// SVG source or raster bytes; `null` falls back to the initials.
    pub fn image(self: Avatar, bytes: ?[]const u8) Avatar {
        var copy = self;
        copy.image_value = bytes;
        return copy;
    }

    pub fn size(self: Avatar, value: Size) Avatar {
        var copy = self;
        copy.size_value = value;
        return copy;
    }

    /// Explicit pixel size, overriding the named `size` when set.
    pub fn sizePx(self: Avatar, value: f32) Avatar {
        var copy = self;
        copy.size_px_value = value;
        return copy;
    }

    pub fn shape(self: Avatar, value: Shape) Avatar {
        var copy = self;
        copy.shape_value = value;
        return copy;
    }

    /// The resolved square size in pixels (no zui element involved).
    pub fn pixelSize(self: Avatar) f32 {
        return self.size_px_value orelse pxFor(self.size_value);
    }

    pub fn render(self: Avatar) zui.Element {
        const px_value = self.pixelSize();
        const circle = self.shape_value == .circle;

        if (self.image_value) |bytes| {
            const pic = zui.img(bytes).size(px_value).object_fit(.cover);
            return if (circle) pic.rounded_full() else pic.rounded_lg();
        }

        var starts: [2]usize = undefined;
        const start_count = wordStartIndices(self.name, &starts);
        var letters_row = zui.div().flex_row().items_center();
        if (self.letters_value) |override| {
            letters_row = letters_row.child(support.strong(override, px_value * 0.4, theme.muted_foreground));
        } else {
            if (start_count >= 1) {
                letters_row = letters_row.child(support.strong(self.name[starts[0] .. starts[0] + 1], px_value * 0.4, theme.muted_foreground));
            }
            if (start_count == 2) {
                letters_row = letters_row.child(support.strong(self.name[starts[1] .. starts[1] + 1], px_value * 0.4, theme.muted_foreground));
            }
        }
        const frame = zui.div().size(px_value).flex_row().items_center().justify_center().bg(theme.muted);
        const shaped = if (circle) frame.rounded_full() else frame.rounded_lg();
        return shaped.child(letters_row);
    }
};

const std = @import("std");

test "pxFor follows shadcn avatar sizes" {
    try std.testing.expectEqual(@as(f32, 24), pxFor(.sm));
    try std.testing.expectEqual(@as(f32, 32), pxFor(.md));
    try std.testing.expectEqual(@as(f32, 40), pxFor(.lg));
    try std.testing.expectEqual(@as(f32, 48), pxFor(.xl));
}

test "wordStartIndices borrows letters from the name" {
    var starts: [2]usize = undefined;
    try std.testing.expectEqual(@as(usize, 2), wordStartIndices("Eddie Lake", &starts));
    try std.testing.expectEqualStrings("E", "Eddie Lake"[starts[0] .. starts[0] + 1]);
    try std.testing.expectEqualStrings("L", "Eddie Lake"[starts[1] .. starts[1] + 1]);
    try std.testing.expectEqual(@as(usize, 1), wordStartIndices("shadcn", &starts));
    try std.testing.expectEqual(@as(usize, 0), wordStartIndices("   ", &starts));
}

test "initials take the first letter of up to two words" {
    var buf: [2]u8 = undefined;
    try std.testing.expectEqualStrings("JD", initials("john doe", &buf));
    try std.testing.expectEqualStrings("S", initials("shadcn", &buf));
    try std.testing.expectEqualStrings("", initials("", &buf));
    try std.testing.expectEqualStrings("JL", initials("  jason   lee  ", &buf));
    try std.testing.expectEqualStrings("FB", initials("foo bar dar", &buf));
}

test "resolution prefers explicit pixels over the named size" {
    try std.testing.expectEqual(@as(f32, 32), Avatar.init("JD").pixelSize());
    try std.testing.expectEqual(@as(f32, 40), Avatar.init("JD").size(.lg).pixelSize());
    try std.testing.expectEqual(@as(f32, 30), Avatar.init("JD").size(.lg).sizePx(30).pixelSize());
}
