//! Dialog and AlertDialog — shadcn/ui's modal dialogs.
//!
//! zui has no portals or z-indices, but it paints siblings in order (later
//! children on top) and every container clips its children. So an overlay is
//! an `absolute().inset(0)` root appended as the **last child of the app's
//! root**: a scrim child covers the window, and the panel child (later
//! sibling) sits on top, centered by the overlay's flex.
//!
//! Mouse events go to the topmost hit region only, and nodes without
//! listeners register no region — so the panel attaches
//! `support.noopListener()` to block clicks on its empty areas from
//! reaching the scrim. The scrim's optional `on_scrim_click` dismisses.
//!
//! ```zig
//! // in the app's root render, as the LAST child:
//! if (self.dialog_open) page = page.child(
//!     Dialog.init()
//!         .title("Are you sure?")
//!         .description("This cannot be undone.")
//!         .footer(cancel_and_action_row)
//!         .onScrimClick(cx.listener(State, closeDialog))
//!         .render(),
//! );
//! ```

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

/// shadcn `dialog` widths: default 425px (`sm`).
pub const default_width: f32 = 425;

/// The scrim color: 60% black over the page.
pub fn scrimColor() zui.Color {
    return zui.rgba(0, 0, 0, 0.6);
}

/// Full-screen overlay root (absolute, centered flex column). Shared by
/// sheet/popover/dropdown overlays too.
pub fn overlayRoot() zui.Element {
    return zui.div().absolute().inset(0).flex_col().items_center().justify_center();
}

/// The scrim layer covering the window; dismisses when a listener is given.
pub fn scrimLayer(on_scrim_click: ?zui.Listener) zui.Element {
    var layer = zui.div().absolute().inset(0).bg(scrimColor());
    if (on_scrim_click) |listener| layer = layer.on_click(listener);
    return layer;
}

fn scrim(on_scrim_click: ?zui.Listener) zui.Element {
    return scrimLayer(on_scrim_click);
}

pub const Dialog = struct {
    title: []const u8 = "",
    description_value: ?[]const u8 = null,
    content_value: ?zui.Element = null,
    footer_value: ?zui.Element = null,
    width_px: f32 = default_width,
    on_scrim_click: ?zui.Listener = null,

    pub fn init() Dialog {
        return .{};
    }

    pub fn titleText(self: Dialog, value: []const u8) Dialog {
        var copy = self;
        copy.title = value;
        return copy;
    }

    pub fn description(self: Dialog, value: ?[]const u8) Dialog {
        var copy = self;
        copy.description_value = value;
        return copy;
    }

    pub fn content(self: Dialog, value: zui.Element) Dialog {
        var copy = self;
        copy.content_value = value;
        return copy;
    }

    pub fn footer(self: Dialog, value: zui.Element) Dialog {
        var copy = self;
        copy.footer_value = value;
        return copy;
    }

    pub fn width(self: Dialog, px: f32) Dialog {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn onScrimClick(self: Dialog, listener: zui.Listener) Dialog {
        var copy = self;
        copy.on_scrim_click = listener;
        return copy;
    }

    /// The full-screen overlay. Append as the last child of the app root.
    pub fn render(self: Dialog) zui.Element {
        var overlay = overlayRoot().child(scrim(self.on_scrim_click));

        var panel = zui.div().w(self.width_px).flex_col().gap(16).p(24)
            .rounded_xl().bg(theme.popover)
            .border_1().border_color(theme.border)
            .shadow_lg()
            .on_click(support.noopListener());

        var header = zui.div().flex_col().gap(4)
            .child(support.strong(self.title, 16, theme.foreground));
        if (self.description_value) |text| {
            header = header.child(support.label(text, 14, theme.muted_foreground));
        }
        panel = panel.child(header);
        if (self.content_value) |element| panel = panel.child(element);
        if (self.footer_value) |element| panel = panel.child(element);

        return overlay.child(panel);
    }
};

/// shadcn `alert-dialog`: a destructive confirmation with a leading icon.
pub const AlertDialog = struct {
    title: []const u8 = "",
    description_value: ?[]const u8 = null,
    /// Cancel control (e.g. `Button.init("Cancel").variant(.outline)`).
    cancel_value: ?zui.Element = null,
    /// Destructive action (e.g. `Button.init("Delete").variant(.destructive)`).
    action_value: ?zui.Element = null,
    width_px: f32 = default_width,
    on_scrim_click: ?zui.Listener = null,

    pub fn init() AlertDialog {
        return .{};
    }

    pub fn titleText(self: AlertDialog, value: []const u8) AlertDialog {
        var copy = self;
        copy.title = value;
        return copy;
    }

    pub fn description(self: AlertDialog, value: ?[]const u8) AlertDialog {
        var copy = self;
        copy.description_value = value;
        return copy;
    }

    pub fn cancel(self: AlertDialog, value: zui.Element) AlertDialog {
        var copy = self;
        copy.cancel_value = value;
        return copy;
    }

    pub fn action(self: AlertDialog, value: zui.Element) AlertDialog {
        var copy = self;
        copy.action_value = value;
        return copy;
    }

    pub fn width(self: AlertDialog, px: f32) AlertDialog {
        var copy = self;
        copy.width_px = px;
        return copy;
    }

    pub fn onScrimClick(self: AlertDialog, listener: zui.Listener) AlertDialog {
        var copy = self;
        copy.on_scrim_click = listener;
        return copy;
    }

    pub fn render(self: AlertDialog) zui.Element {
        var overlay = overlayRoot().child(scrim(self.on_scrim_click));

        var panel = zui.div().w(self.width_px).flex_col().gap(16).p(24)
            .rounded_xl().bg(theme.popover)
            .border_1().border_color(theme.border)
            .shadow_lg()
            .on_click(support.noopListener());

        // Header: warning icon + title, then description.
        panel = panel.child(zui.div().flex_row().items_center().gap(10)
            .child(icon_component.render(semantic.info, 18, theme.destructive))
            .child(support.strong(self.title, 16, theme.foreground)));
        if (self.description_value) |text| {
            panel = panel.child(support.label(text, 14, theme.muted_foreground));
        }

        // Footer: cancel left, action right (no justify_end in zui: spacer).
        var footer_row = zui.div().flex_row().items_center().gap(8);
        if (self.cancel_value) |element| footer_row = footer_row.child(element);
        footer_row = footer_row.child(zui.spacer());
        if (self.action_value) |element| footer_row = footer_row.child(element);
        panel = panel.child(footer_row);

        return overlay.child(panel);
    }
};

const std = @import("std");

test "scrim is translucent black" {
    const color = scrimColor();
    try std.testing.expectApproxEqAbs(@as(f32, 0.6), color.a, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0), color.r, 0.001);
}
