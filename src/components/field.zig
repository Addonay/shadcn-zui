//! Field — shadcn/ui's label + control + description + error wrapper
//! (Mantine/HeroUI call the same thing Field/InputWrapper).

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const Field = struct {
    label_text: []const u8 = "",
    description_text: ?[]const u8 = null,
    error_text: ?[]const u8 = null,
    /// The input control — frame-local, set during render.
    control_value: ?zui.Element = null,
    gap_px: f32 = 8,

    pub fn init(label_text: []const u8) Field {
        return .{ .label_text = label_text };
    }

    pub fn control(self: Field, element: zui.Element) Field {
        var copy = self;
        copy.control_value = element;
        return copy;
    }

    pub fn description(self: Field, text: []const u8) Field {
        var copy = self;
        copy.description_text = text;
        return copy;
    }

    pub fn errorMessage(self: Field, text: []const u8) Field {
        var copy = self;
        copy.error_text = text;
        return copy;
    }

    pub fn gap(self: Field, px: f32) Field {
        var copy = self;
        copy.gap_px = px;
        return copy;
    }

    pub fn render(self: Field) zui.Element {
        var col = zui.div().flex_col().gap(self.gap_px)
            .child(support.label(self.label_text, 13, theme.foreground));
        if (self.control_value) |element| col = col.child(element);
        if (self.error_text) |text| {
            col = col.child(support.label(text, 12, theme.destructive));
        } else if (self.description_text) |text| {
            col = col.child(support.label(text, 12, theme.muted_foreground));
        }
        return col;
    }
};

const std = @import("std");

test "gap default" {
    const field = Field.init("Email");
    try std.testing.expectEqual(@as(f32, 8), field.gap_px);
}
