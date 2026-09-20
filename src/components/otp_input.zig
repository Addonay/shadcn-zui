//! OTPInput / PinInput — shadcn/Mantine's per-cell code input.
//! The value lives in app state (zui TextField entities per cell is the
//! editable route); this file is the chrome + cell math.

const std = @import("std");

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");

pub const cell_size: f32 = 40;

/// Character for a cell, or "" when empty (pure; unit-tested).
pub fn cellValue(value: []const u8, index: usize) []const u8 {
    if (index >= value.len) return "";
    return value[index .. index + 1];
}

/// Whether a cell is the active one for caret styling (pure).
pub fn isActive(value: []const u8, index: usize) bool {
    return index == value.len;
}

pub const OtpInput = struct {
    value_text: []const u8 = "",
    cells: usize = 6,
    invalid_value: bool = false,

    pub fn init() OtpInput {
        return .{};
    }

    pub fn value(self: OtpInput, text: []const u8) OtpInput {
        var copy = self;
        copy.value_text = text;
        return copy;
    }

    pub fn cellCount(self: OtpInput, n: usize) OtpInput {
        var copy = self;
        copy.cells = n;
        return copy;
    }

    pub fn invalid(self: OtpInput, mark: bool) OtpInput {
        var copy = self;
        copy.invalid_value = mark;
        return copy;
    }

    pub fn render(self: OtpInput) zui.Element {
        var row = zui.div().flex_row().items_center().gap(8);
        var index: usize = 0;
        while (index < self.cells) : (index += 1) {
            const filled = cellValue(self.value_text, index).len > 0;
            var slot = zui.div().size(cell_size).flex_row().items_center().justify_center()
                .rounded(8).bg(theme.background)
                .border_1().border_color(if (self.invalid_value) theme.destructive else theme.input_border);
            if (isActive(self.value_text, index)) {
                slot = slot.border_1().border_color(theme.ring);
            }
            if (filled) {
                slot = slot.child(support.strong(cellValue(self.value_text, index), 16, theme.foreground));
            }
            row = row.child(slot);
        }
        return row;
    }
};

test "cell math" {
    try std.testing.expectEqualStrings("4", cellValue("4210", 0));
    try std.testing.expectEqualStrings("0", cellValue("4210", 3));
    try std.testing.expectEqualStrings("", cellValue("421", 3));
    try std.testing.expect(isActive("421", 3));
    try std.testing.expect(!isActive("421", 2));
}
