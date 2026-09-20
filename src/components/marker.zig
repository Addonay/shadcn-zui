//! Marker — gpui-kit's status dot and conversation separator.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");

pub const dot_size: f32 = 8;

pub const Kind = enum { info, success, warning, err, muted };

pub fn colorFor(kind: Kind) zui.Color {
    return switch (kind) {
        .info => theme.chart_2,
        .success => theme.success,
        .warning => theme.warning,
        .err => theme.destructive,
        .muted => theme.muted_foreground,
    };
}

pub const Marker = struct {
    kind: Kind = .info,
    label_text: ?[]const u8 = null,
    /// Renders as a full-width hairline with the label centered on it.
    divider: bool = false,

    pub fn init(kind: Kind) Marker {
        return .{ .kind = kind };
    }

    pub fn label(self: Marker, text: []const u8) Marker {
        var copy = self;
        copy.label_text = text;
        return copy;
    }

    pub fn asDivider(self: Marker) Marker {
        var copy = self;
        copy.divider = true;
        return copy;
    }

    pub fn render(self: Marker) zui.Element {
        const color = colorFor(self.kind);
        if (self.divider) {
            var row = zui.div().flex_row().items_center().gap(12).w_full()
                .child(zui.div().flex_1().h(1).bg(theme.border));
            if (self.label_text) |text| {
                row = row.child(support.label(text, 11, theme.faint))
                    .child(zui.div().flex_1().h(1).bg(theme.border));
            }
            return row;
        }
        var row = zui.div().flex_row().items_center().gap(6)
            .child(zui.div().size(dot_size).rounded_full().bg(color));
        if (self.label_text) |text| {
            row = row.child(support.label(text, 12, theme.muted_foreground));
        }
        return row;
    }
};

const std = @import("std");

test "marker colors" {
    try std.testing.expectEqual(theme.success, colorFor(.success));
    try std.testing.expectEqual(theme.destructive, colorFor(.err));
}
