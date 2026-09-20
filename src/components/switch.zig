//! Switch — shadcn/ui's track-and-thumb toggle.
//!
//! ```zig
//! Switch.init()
//!     .checked(state.enabled)
//!     .size(.md)
//!     .onChange(cx.listener(State, toggleEnabled))
//!     .render()
//! ```
//!
//! Listeners are built by the caller from its own `Context`, so the same
//! component works for any app state type.

const zui = @import("zui");

const theme = @import("../theme.zig");

pub const Size = enum { sm, md };

pub const Metrics = struct {
    track_width: f32,
    track_height: f32,
    thumb: f32,
    padding: f32,
    /// Fully-rounded track/thumb; kept in metrics so layout stays pure data.
    radius: f32,
};

/// gpui-kit's switch metrics: 28x16/12 for small, 36x20/16 for medium, 2px pad.
pub fn metrics(size: Size) Metrics {
    return switch (size) {
        .sm => .{ .track_width = 28, .track_height = 16, .thumb = 12, .padding = 2, .radius = 999 },
        .md => .{ .track_width = 36, .track_height = 20, .thumb = 16, .padding = 2, .radius = 999 },
    };
}

pub const Colors = struct {
    track: zui.Color,
    thumb: zui.Color,
};

pub fn colors(checked: bool) Colors {
    return .{
        .track = if (checked) theme.primary else theme.secondary,
        .thumb = theme.background,
    };
}

pub const Switch = struct {
    checked_value: bool = false,
    size_value: Size = .md,
    disabled_value: bool = false,
    listener: ?zui.elements.Listener = null,

    pub fn init() Switch {
        return .{};
    }

    pub fn checked(self: Switch, value: bool) Switch {
        var copy = self;
        copy.checked_value = value;
        return copy;
    }

    pub fn size(self: Switch, value: Size) Switch {
        var copy = self;
        copy.size_value = value;
        return copy;
    }

    pub fn disabled(self: Switch, value: bool) Switch {
        var copy = self;
        copy.disabled_value = value;
        return copy;
    }

    pub fn onChange(self: Switch, listener: zui.elements.Listener) Switch {
        var copy = self;
        copy.listener = listener;
        return copy;
    }

    pub fn render(self: Switch) zui.Element {
        const m = metrics(self.size_value);
        const c = colors(self.checked_value);

        var track = zui.div().flex_row().items_center()
            .w(m.track_width).h(m.track_height).p(m.padding)
            .rounded_full().bg(c.track);

        if (self.disabled_value) {
            track = track.opacity(0.5);
        } else {
            track = track.cursor_pointer();
            if (self.listener) |listener| track = track.on_click(listener);
        }

        const thumb = zui.div().size(m.thumb).rounded_full().bg(c.thumb);
        // zui has no `justify_end`; a flex_1 spacer on the opposite side is the
        // documented workaround for pushing the thumb to the checked edge.
        if (self.checked_value) {
            track = track.child(zui.spacer()).child(thumb);
        } else {
            track = track.child(thumb).child(zui.spacer());
        }
        return track;
    }
};

const std = @import("std");

test "size metrics match gpui-kit switches" {
    const sm = metrics(.sm);
    try std.testing.expectEqual(@as(f32, 28), sm.track_width);
    try std.testing.expectEqual(@as(f32, 16), sm.track_height);
    try std.testing.expectEqual(@as(f32, 12), sm.thumb);
    try std.testing.expectEqual(@as(f32, 2), sm.padding);

    const md = metrics(.md);
    try std.testing.expectEqual(@as(f32, 36), md.track_width);
    try std.testing.expectEqual(@as(f32, 20), md.track_height);
    try std.testing.expectEqual(@as(f32, 16), md.thumb);
    try std.testing.expectEqual(@as(f32, 2), md.padding);
    try std.testing.expectEqual(@as(f32, 999), md.radius);
}

test "thumb travel stays inside the padded track" {
    inline for (.{ Size.sm, Size.md }) |size| {
        const m = metrics(size);
        try std.testing.expect(m.track_width - m.thumb - m.padding * 2 >= 0);
    }
}

test "colors resolve checked and unchecked tracks" {
    const on = colors(true);
    try std.testing.expectEqual(theme.primary, on.track);
    try std.testing.expectEqual(theme.background, on.thumb);

    const off = colors(false);
    try std.testing.expectEqual(theme.secondary, off.track);
}

test "builder methods return updated copies" {
    const base = Switch.init();
    try std.testing.expect(!base.checked_value);
    try std.testing.expect(base.size_value == .md);
    try std.testing.expect(base.listener == null);

    const configured = base.checked(true).size(.sm).disabled(true);
    try std.testing.expect(configured.checked_value);
    try std.testing.expect(configured.size_value == .sm);
    try std.testing.expect(configured.disabled_value);
    // The original stays untouched (value semantics).
    try std.testing.expect(!base.checked_value);
    try std.testing.expect(base.size_value == .md);
}
