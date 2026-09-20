//! Collapsible — shadcn/ui's open/close region. Controlled.

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const slot_gap: f32 = 8;

pub const Collapsible = struct {
    open_value: bool = false,
    /// The trigger element — the caller attaches its own on_click listener
    /// (e.g. `Button.init("Show more").variant(.outline).onToggle(...)`).
    trigger_value: ?zui.Element = null,
    content_value: ?zui.Element = null,

    pub fn init() Collapsible {
        return .{};
    }

    pub fn open(self: Collapsible, value: bool) Collapsible {
        var copy = self;
        copy.open_value = value;
        return copy;
    }

    pub fn trigger(self: Collapsible, value: zui.Element) Collapsible {
        var copy = self;
        copy.trigger_value = value;
        return copy;
    }

    pub fn content(self: Collapsible, value: zui.Element) Collapsible {
        var copy = self;
        copy.content_value = value;
        return copy;
    }

    pub fn render(self: Collapsible) zui.Element {
        var region = zui.div().flex_col().gap(slot_gap);
        if (self.trigger_value) |element| region = region.child(element);
        if (self.open_value) {
            if (self.content_value) |element| region = region.child(element);
        }
        return region;
    }
};

const std = @import("std");

test "metrics" {
    try std.testing.expectEqual(@as(f32, 8), slot_gap);
}
