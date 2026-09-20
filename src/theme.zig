//! shadcn/ui design tokens, dark theme (the dashboard reference palette).
//!
//! Names follow shadcn/ui's CSS variables so classes map 1:1:
//! `bg-background`, `text-muted-foreground`, `border-border`, ...

const zui = @import("zui");

pub const background = zui.hex(0x121212);
pub const foreground = zui.hex(0xfafafa);
pub const page = zui.hex(0x1e1e1e);

pub const card = zui.hex(0x1e1e1e);
pub const card_metric = zui.hex(0x202020);
pub const card_foreground = foreground;

pub const popover = zui.hex(0x1e1e1e);
pub const popover_foreground = foreground;

pub const primary = zui.hex(0xe5e5e5);
pub const primary_foreground = zui.hex(0x171717);
pub const primary_hover = zui.hex(0xd4d4d4);

pub const secondary = zui.hex(0x262626);
pub const secondary_foreground = zui.hex(0xfafafa);
pub const secondary_hover = zui.hex(0x303030);

pub const muted = zui.hex(0x262626);
pub const muted_foreground = zui.hex(0xa1a1a1);

pub const accent = zui.hex(0x292929);
pub const accent_foreground = zui.hex(0xfafafa);
pub const accent_hover = zui.hex(0x323232);

pub const destructive = zui.hex(0xef4444);
pub const destructive_foreground = zui.hex(0xfafafa);
pub const destructive_hover = zui.hex(0xdc2626);
pub const success = zui.hex(0x0ddf72);
pub const warning = zui.hex(0xfacc15);

pub const border = zui.hex(0x262626);
pub const border_strong = zui.hex(0x343434);
pub const input_border = zui.hex(0x3f3f3f);
pub const ring = zui.hex(0x737373);

pub const sidebar = page;
pub const sidebar_foreground = zui.hex(0xb5b5b5);
pub const sidebar_accent = accent;
pub const sidebar_border = border;

pub const chart_1 = zui.hex(0x93c5fd);
pub const chart_2 = zui.hex(0x3b82f6);
pub const chart_3 = zui.hex(0x2563eb);

pub const body = zui.hex(0xd4d4d4);
pub const faint = zui.hex(0x71717a);
pub const white = zui.hex(0xffffff);

/// shadcn's `--radius` (0.625rem) scaled to the reference's 12px cards.
pub const radius = 12.0;
pub const radius_sm = 8.0;
pub const radius_md = 10.0;
pub const radius_lg = 12.0;
pub const radius_xl = 16.0;

/// The dashboard reference uses Noto Sans on this machine; apps can override.
pub const font = "Noto Sans, sans-serif";

test "palette is opaque and distinct" {
    try @import("std").testing.expectEqual(@as(f32, 1), background.a);
    try @import("std").testing.expect(foreground.r > background.r);
    try @import("std").testing.expect(primary.r > primary_foreground.r);
}
