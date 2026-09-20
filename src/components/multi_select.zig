//! MultiSelect — Mantine/Ant's multi-select as selected chips + a listbox
//! panel the app hosts in a popover. Chip removal is per chip.

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;
const tag_component = @import("tag.zig");

pub const Chip = struct {
    label: []const u8,
    on_remove: ?zui.elements.Listener = null,

    pub fn render(self: Chip) zui.Element {
        var chip = tag_component.Tag.init(self.label).variant(.outline);
        if (self.on_remove) |listener| chip = chip.onRemove(listener);
        return chip.render();
    }
};

/// Summary label for a selected-count (pure; unit-tested).
pub fn summaryLabel(count: usize) []const u8 {
    return switch (count) {
        0 => "None selected",
        1 => "1 selected",
        else => "Several selected",
    };
}

pub const MultiSelect = struct {
    chips: []const Chip,
    on_open: ?zui.elements.Listener = null,

    pub fn init(chips: []const Chip) MultiSelect {
        return .{ .chips = chips };
    }

    pub fn onOpen(self: MultiSelect, listener: zui.elements.Listener) MultiSelect {
        var copy = self;
        copy.on_open = listener;
        return copy;
    }

    pub fn render(self: MultiSelect) zui.Element {
        var row = zui.div().flex_row().flex_wrap().items_center().gap(6)
            .h(38).px(12).rounded_lg().bg(theme.background)
            .border_1().border_color(theme.input_border)
            .hover_bg(theme.accent);
        if (self.on_open) |listener| row = row.cursor_pointer().on_click(listener);
        if (self.chips.len == 0) {
            row = row.child(support.label(summaryLabel(0), 14, theme.muted_foreground));
        }
        for (self.chips) |chip| row = row.child(chip.render());
        row = row.child(zui.spacer());
        row = row.child(icon_component.render(semantic.chevron_down, 16, theme.muted_foreground));
        return row;
    }
};

const std = @import("std");

test "summary labels" {
    try std.testing.expectEqualStrings("None selected", summaryLabel(0));
    try std.testing.expectEqualStrings("1 selected", summaryLabel(1));
    try std.testing.expectEqualStrings("Several selected", summaryLabel(4));
}
