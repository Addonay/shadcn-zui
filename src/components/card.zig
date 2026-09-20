//! Card — shadcn/ui's card anatomy plus the dashboard's metric card.
//!
//! Two entry points live under the `Card` namespace:
//!
//! ```zig
//! // Generic card: header + arbitrary content/footer elements.
//! Card.init()
//!     .title("Payment Method")
//!     .description("Add a new payment method")
//!     .headerTrailing(Button.init("Edit").render())
//!     .content(any_element)
//!     .footer(any_element)
//!     .render();
//!
//! // Dashboard metric card (dash `cards.zig`'s `metricCard`).
//! Card.metric(.{
//!     .title = "Total Revenue",
//!     .value = "$1,250.00",
//!     .delta = "+12.5%",
//!     .foot = "Trending up this month",
//!     .sub = "Visitors for the last 6 months",
//! });
//! ```
//!
//! `Card.init()` returns [`Card.Builder`] rather than `Card` itself so the
//! builder's `.metric(bool)` shell toggle can coexist with the static
//! `Card.metric(Metric)` constructor: Zig has no method overloading, and both
//! spellings are part of the public API.
//!
//! Caller-supplied elements are stored on the builder, so a builder must be
//! constructed and `render()`ed during the same frame (elements are
//! frame-local indices).

const zui = @import("zui");

const theme = @import("../theme.zig");
const support = @import("../support.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

/// shadcn `Card` default padding (`p-6`).
pub const DEFAULT_PADDING: f32 = 24;
/// shadcn `Card` default gap (`gap-6`).
pub const DEFAULT_GAP: f32 = 24;

/// Header block metrics (shadcn `CardHeader`: `gap-1.5`).
pub const HEADER_GAP: f32 = 4;
pub const TITLE_SIZE: f32 = 16;
pub const DESCRIPTION_SIZE: f32 = 14;

/// Dashboard metric-card metrics (dash `cards.zig` `metricCard`).
pub const METRIC_HEIGHT: f32 = 184;
pub const METRIC_PADDING: f32 = 24;
pub const METRIC_VALUE_SIZE: f32 = 30;
pub const DELTA_PILL_HEIGHT: f32 = 22;
pub const DELTA_PILL_PADDING_X: f32 = 8;
pub const DELTA_ICON_SIZE: f32 = 12;
pub const FOOT_ICON_SIZE: f32 = 16;

/// Input to [`Card.metric`]. Mirrors the dashboard's `data.Metric`, with
/// trend direction as booleans (`up` -> `delta_up` / `foot_up`).
pub const Metric = struct {
    title: []const u8,
    value: []const u8,
    delta: []const u8,
    delta_up: bool = true,
    foot: []const u8,
    foot_up: bool = true,
    sub: []const u8,
};

/// Resolved shell colors for a card.
pub const Shell = struct {
    background: zui.Color,
    border: zui.Color,
};

/// `metric` cards use the slightly lighter dashboard surface; the border is
/// the strong token (the dashboard's `card_border` alias).
pub fn shell(metric: bool) Shell {
    return .{
        .background = if (metric) theme.card_metric else theme.card,
        .border = theme.border_strong,
    };
}

/// Resolve the effective padding: `null` means the shadcn default.
pub fn resolvePadding(value: ?f32) f32 {
    return value orelse DEFAULT_PADDING;
}

/// Resolve the effective gap: `null` means the shadcn default.
pub fn resolveGap(value: ?f32) f32 {
    return value orelse DEFAULT_GAP;
}

/// Lucide icon that represents a trend direction.
pub fn trendingIcon(up: bool) icon_component.Name {
    return if (up) semantic.trending_up else semantic.trending_down;
}

pub const Card = struct {
    /// Start a generic card. Returns [`Card.Builder`].
    pub fn init() Builder {
        return .{};
    }

    /// The dashboard metric card: fixed 184px surface, delta pill, value,
    /// spacer, trend foot and sub-line. Mirrors `cards.zig`'s `metricCard`.
    pub fn metric(value: Metric) zui.Element {
        return renderMetric(value);
    }

    /// Chainable configuration for the generic card.
    pub const Builder = struct {
        title_value: ?[]const u8 = null,
        description_value: ?[]const u8 = null,
        header_trailing: ?zui.Element = null,
        content_value: ?zui.Element = null,
        footer_value: ?zui.Element = null,
        padding_value: ?f32 = null,
        gap_value: ?f32 = null,
        width_value: ?f32 = null,
        metric_value: bool = false,

        pub fn title(self: Builder, value: []const u8) Builder {
            var copy = self;
            copy.title_value = value;
            return copy;
        }

        pub fn description(self: Builder, value: []const u8) Builder {
            var copy = self;
            copy.description_value = value;
            return copy;
        }

        /// Element placed at the end of the header row (e.g. an action
        /// button). When set, the title/description block and this element
        /// sit in a `justify_between` row.
        pub fn headerTrailing(self: Builder, value: zui.Element) Builder {
            var copy = self;
            copy.header_trailing = value;
            return copy;
        }

        pub fn content(self: Builder, value: zui.Element) Builder {
            var copy = self;
            copy.content_value = value;
            return copy;
        }

        pub fn footer(self: Builder, value: zui.Element) Builder {
            var copy = self;
            copy.footer_value = value;
            return copy;
        }

        /// Override the shell padding; `null` restores the default 24px.
        pub fn padding(self: Builder, value: ?f32) Builder {
            var copy = self;
            copy.padding_value = value;
            return copy;
        }

        /// Override the shell gap; `null` restores the default 24px.
        pub fn gap(self: Builder, value: ?f32) Builder {
            var copy = self;
            copy.gap_value = value;
            return copy;
        }

        /// Fixed width for the shell; `null` lets the parent size it.
        pub fn width(self: Builder, value: ?f32) Builder {
            var copy = self;
            copy.width_value = value;
            return copy;
        }

        /// Use the dashboard metric surface (`theme.card_metric`) instead of
        /// the default card surface (`theme.card`).
        pub fn metric(self: Builder, value: bool) Builder {
            var copy = self;
            copy.metric_value = value;
            return copy;
        }

        pub fn render(self: Builder) zui.Element {
            const colors = shell(self.metric_value);
            var card = zui.div().flex_col()
                .p(resolvePadding(self.padding_value))
                .gap(resolveGap(self.gap_value))
                .rounded_xl()
                .bg(colors.background)
                .border_1().border_color(colors.border);
            if (self.width_value) |w| card = card.w(w);

            if (self.renderHeader()) |header| card = card.child(header);
            if (self.content_value) |content_el| card = card.child(content_el);
            if (self.footer_value) |footer_el| card = card.child(footer_el);
            return card;
        }

        fn renderHeader(self: Builder) ?zui.Element {
            var block = zui.div().flex_col().gap(HEADER_GAP);
            var has_text = false;
            if (self.title_value) |text| {
                block = block.child(support.strong(text, TITLE_SIZE, theme.foreground));
                has_text = true;
            }
            if (self.description_value) |text| {
                block = block.child(support.label(text, DESCRIPTION_SIZE, theme.muted_foreground));
                has_text = true;
            }

            if (self.header_trailing) |trailing| {
                var row = zui.div().flex_row().items_center().justify_between();
                if (has_text) row = row.child(block);
                row = row.child(trailing);
                return row;
            }
            if (!has_text) return null;
            return block;
        }
    };
};

fn renderMetric(value: Metric) zui.Element {
    return zui.div().flex_col().h(METRIC_HEIGHT).p(METRIC_PADDING).rounded_xl()
        .bg(theme.card_metric)
        .border_1().border_color(theme.border_strong)
        .child(zui.div().flex_row().items_center().justify_between()
            .child(support.label(value.title, 14, theme.muted_foreground))
            .child(deltaPill(value)))
        .child(zui.div().pt(10).child(support.strong(value.value, METRIC_VALUE_SIZE, theme.foreground)))
        .child(zui.spacer())
        .child(zui.div().flex_row().items_center().gap(6)
            .child(support.strong(value.foot, 14, theme.foreground))
            .child(icon_component.render(trendingIcon(value.foot_up), FOOT_ICON_SIZE, theme.foreground)))
        .child(zui.div().pt(6).child(support.label(value.sub, 14, theme.muted_foreground)));
}

fn deltaPill(value: Metric) zui.Element {
    return zui.div().flex_row().items_center().gap(4)
        .h(DELTA_PILL_HEIGHT).px(DELTA_PILL_PADDING_X).rounded_full()
        .border_1().border_color(theme.border_strong)
        .child(icon_component.render(trendingIcon(value.delta_up), DELTA_ICON_SIZE, theme.muted_foreground))
        .child(support.label(value.delta, 12, theme.muted_foreground));
}

const std = @import("std");

test "shell resolves metric vs default surface" {
    const normal = shell(false);
    try std.testing.expectEqual(theme.card, normal.background);
    try std.testing.expectEqual(theme.border_strong, normal.border);

    const metric = shell(true);
    try std.testing.expectEqual(theme.card_metric, metric.background);
    try std.testing.expectEqual(theme.border_strong, metric.border);
}

test "padding and gap fall back to shadcn defaults" {
    try std.testing.expectEqual(@as(f32, 24), resolvePadding(null));
    try std.testing.expectEqual(@as(f32, 16), resolvePadding(16));
    try std.testing.expectEqual(@as(f32, 24), resolveGap(null));
    try std.testing.expectEqual(@as(f32, 32), resolveGap(32));
}

test "builder defaults match shadcn anatomy" {
    const builder = Card.init();
    try std.testing.expect(builder.title_value == null);
    try std.testing.expect(builder.description_value == null);
    try std.testing.expect(builder.header_trailing == null);
    try std.testing.expect(builder.content_value == null);
    try std.testing.expect(builder.footer_value == null);
    try std.testing.expect(builder.padding_value == null);
    try std.testing.expect(builder.gap_value == null);
    try std.testing.expect(builder.width_value == null);
    try std.testing.expect(!builder.metric_value);
    try std.testing.expectEqual(@as(f32, 24), resolvePadding(builder.padding_value));
    try std.testing.expectEqual(@as(f32, 24), resolveGap(builder.gap_value));
}

test "builder chains without mutating the original" {
    const base = Card.init();
    const configured = base
        .title("Payment Method")
        .description("Add a new payment method")
        .metric(true)
        .padding(16)
        .gap(8)
        .width(320);

    try std.testing.expect(base.title_value == null);
    try std.testing.expectEqualStrings("Payment Method", configured.title_value.?);
    try std.testing.expectEqualStrings("Add a new payment method", configured.description_value.?);
    try std.testing.expect(configured.metric_value);
    try std.testing.expectEqual(@as(f32, 16), configured.padding_value.?);
    try std.testing.expectEqual(@as(f32, 8), configured.gap_value.?);
    try std.testing.expectEqual(@as(f32, 320), configured.width_value.?);
}

test "metric trends default to up" {
    const value = Metric{ .title = "t", .value = "v", .delta = "+1%", .foot = "f", .sub = "s" };
    try std.testing.expect(value.delta_up);
    try std.testing.expect(value.foot_up);
    try std.testing.expectEqual(semantic.trending_up, trendingIcon(value.delta_up));

    const down = Metric{ .title = "t", .value = "v", .delta = "-1%", .delta_up = false, .foot = "f", .foot_up = false, .sub = "s" };
    try std.testing.expectEqual(semantic.trending_down, trendingIcon(down.foot_up));
}

test "metric card metrics match the dashboard reference" {
    try std.testing.expectEqual(@as(f32, 184), METRIC_HEIGHT);
    try std.testing.expectEqual(@as(f32, 24), METRIC_PADDING);
    try std.testing.expectEqual(@as(f32, 30), METRIC_VALUE_SIZE);
    try std.testing.expectEqual(@as(f32, 22), DELTA_PILL_HEIGHT);
    try std.testing.expectEqual(@as(f32, 8), DELTA_PILL_PADDING_X);
    try std.testing.expectEqual(@as(f32, 12), DELTA_ICON_SIZE);
    try std.testing.expectEqual(@as(f32, 16), FOOT_ICON_SIZE);
}
