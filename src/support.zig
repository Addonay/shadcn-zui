//! Small shared builders (the library's version of the dashboard's `ui.zig`).

const zui = @import("zui");

const theme = @import("theme.zig");

/// Body text at an explicit size and color, line box 6px taller than the
/// glyphs (matches the dashboard's label rhythm).
pub fn label(value: []const u8, size: f32, color: zui.Color) zui.Element {
    return zui.text(value, .{ .font = theme.font, .size = size, .line_height = size + 6, .color = color });
}

/// Semibold text, same rhythm as `label`.
pub fn strong(value: []const u8, size: f32, color: zui.Color) zui.Element {
    return zui.text(value, .{ .font = theme.font, .size = size, .line_height = size + 6, .weight = .semibold, .color = color });
}

/// A square SVG icon tinted to `color`.
pub fn icon(name: @import("components/icon/root.zig").Name, size: f32, color: zui.Color) zui.Element {
    return @import("components/icon/root.zig").render(name, size, color);
}

/// A `zui.Listener` that does nothing.
///
/// zui dispatches mouse events to the topmost hit region only, and a node
/// without a listener registers no region. Overlay panels (dialog, sheet,
/// popover, menu) attach this so clicks on their empty areas don't fall
/// through to the scrim behind them; their interactive children still win
/// because they register later (higher) regions.
var noop_target: u8 = 0;

fn noopCall(_: *anyopaque, _: *const zui.elements.element.ListenerPayload, _: *anyopaque) void {}

pub fn noopListener() zui.Listener {
    return .{ .target = @ptrCast(&noop_target), .call_fn = noopCall };
}
