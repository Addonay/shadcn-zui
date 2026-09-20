//! Empty — shadcn/ui's empty state (dashed border, centered content).

const zui = @import("zui");

const icon_component = @import("icon/root.zig");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const padding: f32 = 32;
pub const radius: f32 = 12;

pub const Empty = struct {
    title: []const u8 = "",
    description_value: ?[]const u8 = null,
    icon_value: ?icon_component.Name = null,
    action_value: ?zui.Element = null,
    height_px: ?f32 = null,
    dashed_value: bool = true,

    pub fn init(title: []const u8) Empty {
        return .{ .title = title };
    }

    pub fn description(self: Empty, value: ?[]const u8) Empty {
        var copy = self;
        copy.description_value = value;
        return copy;
    }

    pub fn icon(self: Empty, name: icon_component.Name) Empty {
        var copy = self;
        copy.icon_value = name;
        return copy;
    }

    /// Usually a button row; rendered below the text.
    pub fn action(self: Empty, value: zui.Element) Empty {
        var copy = self;
        copy.action_value = value;
        return copy;
    }

    /// Fixed height (centers the content vertically); null sizes to content.
    pub fn height(self: Empty, px: f32) Empty {
        var copy = self;
        copy.height_px = px;
        return copy;
    }

    pub fn dashed(self: Empty, value: bool) Empty {
        var copy = self;
        copy.dashed_value = value;
        return copy;
    }

    pub fn render(self: Empty) zui.Element {
        var block = zui.div().flex_col().items_center().justify_center().gap(8).p(padding)
            .rounded(radius)
            .border_1().border_color(theme.border);
        if (self.dashed_value) block = block.border_dashed();
        if (self.height_px) |px| block = block.h(px);

        if (self.icon_value) |name| {
            block = block.child(icon_component.render(name, 24, theme.faint));
        }
        block = block.child(support.strong(self.title, 16, theme.foreground));
        if (self.description_value) |text| {
            block = block.child(support.label(text, 14, theme.muted_foreground));
        }
        if (self.action_value) |element| {
            block = block.child(zui.div().flex_row().justify_center().pt(4).child(element));
        }
        return block;
    }
};

const std = @import("std");

test "metrics" {
    try std.testing.expectEqual(@as(f32, 32), padding);
    try std.testing.expectEqual(@as(f32, 12), radius);
}
