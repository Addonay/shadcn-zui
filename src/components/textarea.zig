//! Textarea — shadcn/ui's multi-line input chrome (presentational).
//!
//! Editable single-line text uses zui's `TextField` entity; zui has no
//! multi-line editor yet, so this is the styled surface the docs preview
//! with, and the seam a future editor integration will fill.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const text_size: f32 = 14;
pub const line_height: f32 = 20;
pub const padding: f32 = 12;
pub const radius: f32 = 8;

/// Box height for a given row count (padding top+bottom + rows of text).
pub fn heightFor(rows: usize) f32 {
    return padding * 2 + @as(f32, @floatFromInt(rows)) * line_height;
}

pub const Palette = struct {
    border: zui.Color,
    value: zui.Color,
    placeholder: zui.Color,
};

pub fn colors(invalid: bool) Palette {
    return if (invalid)
        .{ .border = theme.destructive, .value = theme.foreground, .placeholder = theme.muted_foreground }
    else
        .{ .border = theme.input_border, .value = theme.foreground, .placeholder = theme.muted_foreground };
}

pub const Textarea = struct {
    placeholder_text: []const u8 = "",
    value_text: ?[]const u8 = null,
    rows_value: usize = 4,
    width_px: ?f32 = null,
    disabled_value: bool = false,
    invalid_value: bool = false,

    pub fn init() Textarea {
        return .{};
    }

    pub fn placeholder(self: Textarea, text: []const u8) Textarea {
        var copy = self;
        copy.placeholder_text = text;
        return copy;
    }

    pub fn value(self: Textarea, text: ?[]const u8) Textarea {
        var copy = self;
        copy.value_text = text;
        return copy;
    }

    pub fn rows(self: Textarea, count: usize) Textarea {
        var copy = self;
        copy.rows_value = count;
        return copy;
    }

    pub fn width(self: Textarea, px: f32) Textarea {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn disabled(self: Textarea, state: bool) Textarea {
        var copy = self;
        copy.disabled_value = state;
        return copy;
    }

    pub fn invalid(self: Textarea, state: bool) Textarea {
        var copy = self;
        copy.invalid_value = state;
        return copy;
    }

    pub fn render(self: Textarea) zui.Element {
        const palette = colors(self.invalid_value);
        const text = self.value_text orelse self.placeholder_text;
        const color = if (self.value_text != null) palette.value else palette.placeholder;

        var box = zui.div().flex_col().h(heightFor(self.rows_value)).p(padding)
            .rounded(radius).border_1().border_color(palette.border);
        box = if (self.width_px) |px| box.w(px) else box.w_full();
        if (self.disabled_value) box = box.opacity(0.5);
        return box.child(support.label(text, text_size, color));
    }
};

const std = @import("std");

test "height grows with rows" {
    try std.testing.expectEqual(@as(f32, 24 + 4 * 20), heightFor(4));
    try std.testing.expectEqual(@as(f32, 24 + 8 * 20), heightFor(8));
}

test "palette follows invalid" {
    try std.testing.expectEqual(theme.input_border, colors(false).border);
    try std.testing.expectEqual(theme.destructive, colors(true).border);
}
