//! Tag — Ant/Mantine's closable category chip (Badge's rounder sibling).

const zui = @import("zui");

const support = @import("../support.zig");
const theme = @import("../theme.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

pub const height_px: f32 = 24;

pub const TagVariant = enum { default, outline, primary, destructive, success };

/// Chip foreground/pair color for a variant (pure; unit-tested).
pub fn pairFor(variant: TagVariant) struct { zui.Color, zui.Color } {
    return switch (variant) {
        .default => .{ theme.secondary, theme.secondary_foreground },
        .outline => .{ theme.background, theme.foreground },
        .primary => .{ theme.primary, theme.primary_foreground },
        .destructive => .{ theme.destructive, theme.destructive_foreground },
        .success => .{ theme.success, theme.background },
    };
}

pub const Tag = struct {
    text: []const u8,
    variant_kind: TagVariant = .default,
    /// Optional remove ("x") listener; shows the close button when set.
    on_remove: ?zui.elements.Listener = null,

    pub fn init(text: []const u8) Tag {
        return .{ .text = text };
    }

    pub fn variant(self: Tag, kind: TagVariant) Tag {
        var copy = self;
        copy.variant_kind = kind;
        return copy;
    }

    pub fn onRemove(self: Tag, listener: zui.elements.Listener) Tag {
        var copy = self;
        copy.on_remove = listener;
        return copy;
    }

    pub fn render(self: Tag) zui.Element {
        const pair = pairFor(self.variant_kind);
        var chip = zui.div().flex_row().items_center().gap(6).h(height_px).px(10)
            .rounded(6).bg(pair[0])
            .child(support.label(self.text, 12, pair[1]));
        if (self.on_remove) |listener| {
            chip = chip.cursor_pointer().hover_bg(theme.accent)
                .child(icon_component.render(semantic.close, 12, theme.muted_foreground))
                .on_click(listener);
        }
        return chip;
    }
};

const std = @import("std");

test "pair colors map by variant" {
    const outline = pairFor(.outline);
    try std.testing.expectEqual(theme.background, outline[0]);
    try std.testing.expectEqual(theme.destructive, pairFor(.destructive)[0]);
}
