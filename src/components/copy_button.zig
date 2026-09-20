//! CopyButton — a copy-to-clipboard button (gpui-kit's `clipboard`).
//!
//! The button is styled here; the copy itself is the app's listener,
//! because the text to copy and the window handle live in the app:
//!
//! ```zig
//! CopyButton.init()
//!     .onCopy(cx.listenerWith([]const u8, State, copySource, self.source_text))
//!     .render()
//!
//! fn copyText(state: *State, source: []const u8, window: *zui.Window, cx: *zui.Context(State)) void {
//!     _ = window.writeClipboard(source);
//!     state.copied = true;
//!     cx.notify();
//! }
//! ```
//!
//! `[]const u8` fits zui's 16-byte listener payload exactly.

const zui = @import("zui");

const button_component = @import("button.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

/// The glyph for the current copied state (pure; unit-tested).
pub fn glyph(copied: bool) icon_component.Name {
    return if (copied) semantic.check else semantic.copy;
}

pub const CopyButton = struct {
    /// Shown after a successful copy (apps flip it in their listener).
    copied: bool = false,
    variant_value: button_component.Variant = .ghost,
    disabled_value: bool = false,
    listener: ?zui.Listener = null,

    pub fn init() CopyButton {
        return .{};
    }

    pub fn variant(self: CopyButton, value: button_component.Variant) CopyButton {
        var copy = self;
        copy.variant_value = value;
        return copy;
    }

    pub fn disabled(self: CopyButton, value: bool) CopyButton {
        var copy = self;
        copy.disabled_value = value;
        return copy;
    }

    pub fn onCopy(self: CopyButton, listener: zui.Listener) CopyButton {
        var copy = self;
        copy.listener = listener;
        return copy;
    }

    pub fn render(self: CopyButton) zui.Element {
        var button = button_component.IconButton
            .init(glyph(self.copied))
            .variant(self.variant_value)
            .disabled(self.disabled_value);
        if (self.listener) |listener| {
            button = button.onClick(listener);
        }
        return button.render();
    }
};

const std = @import("std");

test "glyph flips to a check after copying" {
    try std.testing.expectEqual(semantic.copy, glyph(false));
    try std.testing.expectEqual(semantic.check, glyph(true));
}
