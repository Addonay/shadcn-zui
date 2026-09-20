//! Image — gpui-kit/shadcn's image wrapper with size, fit and fallback.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Image = struct {
    /// PNG bytes (or any format zui decodes); owned by the caller.
    bytes: []const u8 = "",
    width_px: ?f32 = null,
    height_px: ?f32 = null,
    rounded_px: f32 = 8,
    /// Shown when `bytes` is empty.
    fallback_text: ?[]const u8 = null,

    pub fn init(bytes: []const u8) Image {
        return .{ .bytes = bytes };
    }

    pub fn size(self: Image, w: f32, h: f32) Image {
        var copy = self;
        copy.width_px = w;
        copy.height_px = h;
        return copy;
    }

    pub fn rounded(self: Image, px: f32) Image {
        var copy = self;
        copy.rounded_px = px;
        return copy;
    }

    pub fn fallback(self: Image, text: []const u8) Image {
        var copy = self;
        copy.fallback_text = text;
        return copy;
    }

    pub fn render(self: Image) zui.Element {
        if (self.bytes.len == 0) {
            var frame = zui.div().flex_row().items_center().justify_center()
                .rounded(self.rounded_px).bg(theme.secondary)
                .border_1().border_color(theme.border);
            frame = if (self.width_px) |w| frame.w(w) else frame.size(160);
            if (self.height_px) |h| frame = frame.h(h);
            frame = frame.child(support.label(
                self.fallback_text orelse "No image",
                13,
                theme.muted_foreground,
            ));
            return frame;
        }
        var element = zui.img(self.bytes).rounded(self.rounded_px);
        if (self.width_px) |w| element = element.w(w);
        if (self.height_px) |h| element = element.h(h);
        return element;
    }
};

const std = @import("std");

test "defaults" {
    const image = Image.init("");
    try std.testing.expectEqual(@as(f32, 8), image.rounded_px);
    try std.testing.expect(image.fallback_text == null);
}
