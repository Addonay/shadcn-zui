//! Attachment — gpui-kit/shadcn's file chip: type icon, name, size, remove.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

/// Icon for a filename based on its extension (pure; unit-tested).
pub fn iconForName(name: []const u8) icon_component.Name {
    const extension = blk: {
        const dot = std.mem.lastIndexOfScalar(u8, name, '.') orelse break :blk "";
        break :blk name[dot + 1 ..];
    };
    if (std.ascii.eqlIgnoreCase(extension, "png") or std.ascii.eqlIgnoreCase(extension, "jpg") or
        std.ascii.eqlIgnoreCase(extension, "jpeg") or std.ascii.eqlIgnoreCase(extension, "gif") or
        std.ascii.eqlIgnoreCase(extension, "webp")) return semantic.file_image;
    if (std.ascii.eqlIgnoreCase(extension, "pdf")) return semantic.file;
    if (std.ascii.eqlIgnoreCase(extension, "zip") or std.ascii.eqlIgnoreCase(extension, "gz")) return semantic.archive;
    if (std.ascii.eqlIgnoreCase(extension, "mp3") or std.ascii.eqlIgnoreCase(extension, "wav")) return semantic.audio;
    if (std.ascii.eqlIgnoreCase(extension, "mp4") or std.ascii.eqlIgnoreCase(extension, "mov")) return semantic.video;
    return semantic.paperclip;
}

pub const Attachment = struct {
    file_name: []const u8,
    /// Human-formatted size ("2.4 MB"), borrowed until paint.
    size_text: ?[]const u8 = null,
    on_remove: ?zui.elements.Listener = null,

    pub fn init(file_name: []const u8) Attachment {
        return .{ .file_name = file_name };
    }

    pub fn sizeText(self: Attachment, text: []const u8) Attachment {
        var copy = self;
        copy.size_text = text;
        return copy;
    }

    pub fn onRemove(self: Attachment, listener: zui.elements.Listener) Attachment {
        var copy = self;
        copy.on_remove = listener;
        return copy;
    }

    pub fn render(self: Attachment) zui.Element {
        var chip = zui.div().flex_row().items_center().gap(8).h(36).px(10)
            .rounded_lg().bg(theme.secondary)
            .border_1().border_color(theme.border)
            .child(icon_component.render(iconForName(self.file_name), 16, theme.muted_foreground));
        var col = zui.div().flex_col().gap(1)
            .child(support.label(self.file_name, 13, theme.foreground));
        if (self.size_text) |text| {
            col = col.child(support.label(text, 11, theme.faint));
        }
        chip = chip.child(col);
        if (self.on_remove) |listener| {
            chip = chip.child(zui.div().size(24).flex_row().items_center().justify_center()
                .rounded(6).cursor_pointer().hover_bg(theme.accent)
                .child(icon_component.render(semantic.close, 14, theme.muted_foreground))
                .on_click(listener));
        }
        return chip;
    }
};

const std = @import("std");

test "file-type icons" {
    try std.testing.expectEqual(semantic.file_image, iconForName("shot.png"));
    try std.testing.expectEqual(semantic.file, iconForName("spec.PDF"));
    try std.testing.expectEqual(semantic.paperclip, iconForName("README"));
}
