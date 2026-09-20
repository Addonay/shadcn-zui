//! Result — Ant's status page: icon, title, description, actions.

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

pub const Status = enum { success, warning, err, info };

/// Status icon and color pair (pure; unit-tested).
pub fn iconFor(status: Status) struct { icon_component.Name, zui.Color } {
    return switch (status) {
        .success => .{ semantic.success, theme.success },
        .warning => .{ semantic.alert, theme.warning },
        .err => .{ semantic.error_state, theme.destructive },
        .info => .{ semantic.info, theme.chart_2 },
    };
}

pub const Result = struct {
    title_text: []const u8,
    status_kind: Status = .info,
    description_text: ?[]const u8 = null,
    /// Action buttons — frame-local, set during render.
    actions_value: ?zui.Element = null,

    pub fn init(title_text: []const u8) Result {
        return .{ .title_text = title_text };
    }

    pub fn status(self: Result, kind: Status) Result {
        var copy = self;
        copy.status_kind = kind;
        return copy;
    }

    pub fn description(self: Result, text: []const u8) Result {
        var copy = self;
        copy.description_text = text;
        return copy;
    }

    pub fn actions(self: Result, element: zui.Element) Result {
        var copy = self;
        copy.actions_value = element;
        return copy;
    }

    pub fn render(self: Result) zui.Element {
        const pair = iconFor(self.status_kind);
        var col = zui.div().flex_col().items_center().gap(8).py(24)
            .child(icon_component.render(pair[0], 40, pair[1]))
            .child(support.strong(self.title_text, 20, theme.foreground));
        if (self.description_text) |text| {
            col = col.child(support.label(text, 14, theme.muted_foreground));
        }
        if (self.actions_value) |element| {
            col = col.child(zui.div().flex_row().items_center().gap(8).pt(8).child(element));
        }
        return col;
    }
};

const std = @import("std");

test "status icons map" {
    const success = iconFor(.success);
    try std.testing.expectEqual(theme.success, success[1]);
    const error_pair = iconFor(.err);
    try std.testing.expectEqual(theme.destructive, error_pair[1]);
}
