//! LoadingOverlay — Mantine's dimmed scrim with a centered spinner.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");
const spinner_component = @import("spinner.zig");

/// Scrim alpha for the visible state (pure; unit-tested).
pub fn scrimAlpha(visible: bool) f32 {
    return if (visible) 0.72 else 0;
}

pub const LoadingOverlay = struct {
    visible_value: bool = false,
    label_text: ?[]const u8 = null,
    spinner_value: spinner_component.Spinner = .{},

    pub fn init() LoadingOverlay {
        return .{ .visible_value = true };
    }

    pub fn visible(self: LoadingOverlay, value: bool) LoadingOverlay {
        var copy = self;
        copy.visible_value = value;
        return copy;
    }

    pub fn label(self: LoadingOverlay, text: []const u8) LoadingOverlay {
        var copy = self;
        copy.label_text = text;
        return copy;
    }

    /// Call each frame while animating to advance the spinner sweep.
    pub fn spinner(self: LoadingOverlay, value: spinner_component.Spinner) LoadingOverlay {
        var copy = self;
        copy.spinner_value = value;
        return copy;
    }

    pub fn render(self: *LoadingOverlay) zui.Element {
        if (!self.visible_value) return zui.div().opacity(0);
        var col = zui.div().flex_col().items_center().gap(10)
            .child(self.spinner_value.size(24).color(theme.foreground).render());
        if (self.label_text) |text| {
            col = col.child(support.label(text, 13, theme.body));
        }
        return zui.div().absolute().inset(0).flex_row().items_center().justify_center()
            .bg(theme.background).opacity(scrimAlpha(true))
            .child(col);
    }
};

const std = @import("std");

test "scrim alpha" {
    try std.testing.expectEqual(@as(f32, 0.72), scrimAlpha(true));
    try std.testing.expectEqual(@as(f32, 0), scrimAlpha(false));
}
