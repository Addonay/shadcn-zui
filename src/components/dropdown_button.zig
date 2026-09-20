//! DropdownButton — gpui-kit's button that opens a dropdown menu.
//! The button is inline; the menu itself renders at the app root (the app
//! opens a DropdownMenu anchored at the pointer).

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const button_component = @import("button.zig");
const icon_component = @import("icon/root.zig");

pub const DropdownButton = struct {
    label_text: []const u8,
    variant_kind: button_component.Variant = .outline,
    size_kind: button_component.Size = .md,
    /// Fired with the button clicked; the app opens its menu at the pointer.
    on_open: ?zui.elements.Listener = null,

    pub fn init(label_text: []const u8) DropdownButton {
        return .{ .label_text = label_text };
    }

    pub fn variant(self: DropdownButton, kind: button_component.Variant) DropdownButton {
        var copy = self;
        copy.variant_kind = kind;
        return copy;
    }

    pub fn size(self: DropdownButton, kind: button_component.Size) DropdownButton {
        var copy = self;
        copy.size_kind = kind;
        return copy;
    }

    pub fn onOpen(self: DropdownButton, listener: zui.elements.Listener) DropdownButton {
        var copy = self;
        copy.on_open = listener;
        return copy;
    }

    pub fn render(self: DropdownButton) zui.Element {
        var button = button_component.Button.init(self.label_text)
            .variant(self.variant_kind)
            .size(self.size_kind)
            .trailingIcon(.chevron_down);
        if (self.on_open) |listener| button = button.onClick(listener);
        return button.render();
    }
};

const std = @import("std");

test "defaults" {
    const button = DropdownButton.init("Open");
    try std.testing.expect(button.on_open == null);
    try std.testing.expectEqual(button_component.Variant.outline, button.variant_kind);
}
