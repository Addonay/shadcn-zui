//! Slider — a draggable value control, implemented as a zui entity widget
//! (like `zui.TextField`) so it can own its drag state.
//!
//! ```zig
//! // state:
//! volume: Entity(shadcn.Slider),
//! // init:
//! .volume = cx.new(shadcn.Slider, .{ .min = 0, .max = 100, .value = 40, .step = 1 }),
//! // render:
//! child(self.volume.toElement())
//! // read:
//! const v = self.volume.read().value;
//! ```
//!
//! The thumb drags via mouse capture; zui keeps delivering move/up events
//! to the pressed control after the pointer leaves it, so dragging works
//! even when the pointer leaves the track. Jump-to-click isn't supported
//! (track origin isn't known before layout) — drag from the thumb.

const std = @import("std");

const zui = @import("zui");
const support = @import("../support.zig");
const theme = @import("../theme.zig");

/// Fraction of `value` inside `[min, max]`, clamped to 0..1 (pure).
pub fn fraction(value: f32, min: f32, max: f32) f32 {
    if (max <= min) return 0;
    return std.math.clamp((value - min) / (max - min), 0, 1);
}

/// Clamp and snap a raw value to the range/step (pure).
pub fn snapped(value: f32, min: f32, max: f32, step: f32) f32 {
    var result = @max(min, @min(value, max));
    if (step > 0) {
        result = min + @round((result - min) / step) * step;
        result = @max(min, @min(result, max));
    }
    return result;
}

/// Value after a drag: the value at press translated by the pointer delta
/// across the track width, clamped and snapped (pure).
pub fn draggedValue(value_at_press: f32, press_x: f32, now_x: f32, width_px: f32, min: f32, max: f32, step: f32) f32 {
    const span = max - min;
    const delta = (now_x - press_x) / @max(1, width_px) * span;
    return snapped(value_at_press + delta, min, max, step);
}

pub const Slider = struct {
    pub const Options = struct {
        min: f32 = 0,
        max: f32 = 100,
        value: f32 = 0,
        /// Snap increment; 0 = continuous.
        step: f32 = 0,
        width_px: f32 = 320,
        track_px: f32 = 4,
        thumb_px: f32 = 16,
    };

    min: f32 = 0,
    max: f32 = 100,
    value: f32 = 0,
    step: f32 = 0,
    width_px: f32 = 320,
    track_px: f32 = 4,
    thumb_px: f32 = 16,
    dragging: bool = false,
    press_x: f32 = 0,
    value_at_press: f32 = 0,

    pub fn init(_: *zui.Context(@This()), options: Options) @This() {
        return .{
            .min = options.min,
            .max = options.max,
            .value = snapped(options.value, options.min, options.max, options.step),
            .step = options.step,
            .width_px = options.width_px,
            .track_px = options.track_px,
            .thumb_px = options.thumb_px,
        };
    }

    pub fn setValue(self: *@This(), next: f32, cx: *zui.Context(@This())) void {
        const clamped = snapped(next, self.min, self.max, self.step);
        if (clamped == self.value) return;
        self.value = clamped;
        cx.notify();
    }

    pub fn render(self: *@This(), _: *zui.Window, cx: *zui.Context(@This())) zui.Element {
        const frac = fraction(self.value, self.min, self.max);
        const fill_px = frac * (self.width_px - self.thumb_px) + self.thumb_px / 2;

        var row = zui.div().w(self.width_px).h(self.thumb_px).flex_row().items_center()
            .child(zui.div().w(fill_px).h(self.track_px).rounded_full().bg(theme.primary))
            .child(zui.div().flex_1().h(self.track_px).rounded_full().bg(theme.secondary));

        // Thumb: absolute over the track; dragging uses press-relative
        // deltas, so the control never needs its window position.
        var thumb = zui.div().absolute().left(frac * (self.width_px - self.thumb_px)).top(0)
            .size(self.thumb_px).flex_row().items_center().justify_center()
            .rounded_full().bg(theme.background)
            .border_1().border_color(theme.primary)
            .cursor_pointer()
            .on_mouse_down(cx.listener(@This(), beginDrag))
            .on_mouse_move(cx.listener(@This(), moveDrag))
            .on_mouse_up(cx.listener(@This(), endDrag));
        _ = &thumb;

        return row.child(thumb);
    }

    fn beginDrag(self: *@This(), window: *zui.Window, cx: *zui.Context(@This())) void {
        const pointer = window.pointerPosition();
        self.dragging = true;
        self.press_x = pointer.x;
        self.value_at_press = self.value;
        cx.notify();
    }

    fn moveDrag(self: *@This(), window: *zui.Window, cx: *zui.Context(@This())) void {
        if (!self.dragging) return;
        const pointer = window.pointerPosition();
        const next = draggedValue(self.value_at_press, self.press_x, pointer.x, self.width_px, self.min, self.max, self.step);
        if (next != self.value) {
            self.value = next;
            cx.notify();
        }
    }

    fn endDrag(self: *@This(), _: *zui.Window, cx: *zui.Context(@This())) void {
        if (!self.dragging) return;
        self.dragging = false;
        cx.notify();
    }
};

test "fraction clamps and handles inverted ranges" {
    try std.testing.expectApproxEqAbs(@as(f32, 0), fraction(0, 0, 100), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), fraction(50, 0, 100), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 1), fraction(200, 0, 100), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0), fraction(10, 10, 10), 0.001);
}

test "snapping clamps and rounds to the step" {
    try std.testing.expectApproxEqAbs(@as(f32, 100), snapped(200, 0, 100, 10), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 30), snapped(32, 0, 100, 10), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0), snapped(-5, 0, 100, 10), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 3.7), snapped(3.7, 0, 10, 0), 0.001);
}

test "drag translation uses the track width" {
    // Press at the 50% point (value 50 of 0..100 on a 320px track), drag
    // right by 32px = 10% of the track = +10 units.
    try std.testing.expectApproxEqAbs(@as(f32, 60), draggedValue(50, 160, 192, 320, 0, 100, 0), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 40), draggedValue(50, 160, 128, 320, 0, 100, 0), 0.001);
    // Clamped at the rails.
    try std.testing.expectApproxEqAbs(@as(f32, 100), draggedValue(50, 160, 960, 320, 0, 100, 0), 0.001);
}
