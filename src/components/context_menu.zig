//! ContextMenu — shadcn/gpui-kit's menu opened at the pointer (right-click).
//! The trigger is the app's responsibility (a right-click listener); the
//! overlay is the shared dropdown-menu renderer anchored at the pointer.

const zui = @import("zui");

const dropdown = @import("dropdown_menu.zig");

/// A context menu is the dropdown-menu overlay at the pointer position.
pub const ContextMenu = struct {
    inner: dropdown.DropdownMenu,

    pub fn init(items: []const dropdown.Item) ContextMenu {
        return .{ .inner = dropdown.DropdownMenu.init(items) };
    }

    /// Anchor point (usually the right-click position).
    pub fn at(self: ContextMenu, x: f32, y: f32) ContextMenu {
        var copy = self;
        copy.inner = copy.inner.at(x, y);
        return copy;
    }

    pub fn width(self: ContextMenu, px: f32) ContextMenu {
        var copy = self;
        copy.inner = copy.inner.width(px);
        return copy;
    }

    pub fn onScrimClick(self: ContextMenu, listener: zui.elements.Listener) ContextMenu {
        var copy = self;
        copy.inner = copy.inner.onScrimClick(listener);
        return copy;
    }

    pub fn render(self: ContextMenu) zui.Element {
        return self.inner.render();
    }
};

const std = @import("std");

test "reuses the dropdown metrics" {
    try std.testing.expectEqual(dropdown.default_width, (ContextMenu.init(&.{}).inner.width_px));
}
