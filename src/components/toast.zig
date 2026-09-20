//! Toast — shadcn/sonner-style toast card.
//!
//! The component is the card; the app owns the stack. Render toasts in a
//! fixed column near the bottom-right of the app root (absolute):
//!
//! ```zig
//! // in the root render, after everything else:
//! var stack = zui.div().absolute().right(16).bottom(16).flex_col().gap(8);
//! for (&self.toasts) |*toast| {
//!     stack = stack.child(toast_card);
//! }
//! page = page.child(stack);
//! ```

const zui = @import("zui");

const button_component = @import("button.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;
const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const default_width: f32 = 356;
pub const padding: f32 = 16;

pub const Variant = enum { default, success, destructive };

/// Leading icon and accent per variant (pure; unit-tested).
pub fn iconFor(variant: Variant) icon_component.Name {
    return switch (variant) {
        .default => semantic.info,
        .success => semantic.success,
        .destructive => semantic.info,
    };
}

pub fn accentFor(variant: Variant) zui.Color {
    return switch (variant) {
        .default => theme.foreground,
        .success => theme.success,
        .destructive => theme.destructive,
    };
}

pub const Toast = struct {
    title: []const u8 = "",
    description_value: ?[]const u8 = null,
    variant_value: Variant = .default,
    on_dismiss: ?zui.Listener = null,

    pub fn init(title: []const u8) Toast {
        return .{ .title = title };
    }

    pub fn description(self: Toast, value: ?[]const u8) Toast {
        var copy = self;
        copy.description_value = value;
        return copy;
    }

    pub fn variant(self: Toast, value: Variant) Toast {
        var copy = self;
        copy.variant_value = value;
        return copy;
    }

    /// Dismiss (close) listener from the app.
    pub fn onDismiss(self: Toast, listener: zui.Listener) Toast {
        var copy = self;
        copy.on_dismiss = listener;
        return copy;
    }

    pub fn render(self: Toast) zui.Element {
        var card = zui.div().w(default_width).flex_row().gap(10).p(padding)
            .rounded_lg().bg(theme.popover)
            .border_1().border_color(theme.border_strong)
            .shadow_lg();

        // Leading accent icon for the variant.
        card = card.child(icon_component.render(iconFor(self.variant_value), 16, accentFor(self.variant_value)));

        var body = zui.div().flex_col().gap(2).flex_1()
            .child(support.strong(self.title, 14, theme.foreground));
        if (self.description_value) |text| {
            body = body.child(support.label(text, 13, theme.muted_foreground));
        }
        card = card.child(body);

        var close = button_component.IconButton.init(.x).variant(.ghost).size(24, 14);
        if (self.on_dismiss) |listener| {
            close = close.onClick(listener);
        }
        card = card.child(close.render());
        return card;
    }
};

const std = @import("std");

test "variant icons and accents" {
    try std.testing.expectEqual(semantic.info, iconFor(.default));
    try std.testing.expectEqual(semantic.success, iconFor(.success));
    try std.testing.expectEqual(semantic.info, iconFor(.destructive));
    try std.testing.expectEqual(theme.success, accentFor(.success));
    try std.testing.expectEqual(theme.destructive, accentFor(.destructive));
}
