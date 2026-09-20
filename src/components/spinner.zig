//! Spinner — a rotating Lucide glyph.
//!
//! zui has no rotation transform, so — like the dashboard reference — the SVG
//! is rebuilt each frame: the opening `<svg ...>` tag is followed by a
//! `<g transform="rotate(angle 12 12)">` wrapper and `</g>` is appended before
//! `</svg>`. Call `tick` from the frame callback, then `render`.
//!
//! ```zig
//! var spinner = Spinner.init().size(16).color(theme.muted_foreground);
//! // each frame:
//! spinner.tick(dt);
//! element = spinner.render();
//! ```

const zui = @import("zui");

const theme = @import("../theme.zig");
const icon_component = @import("icon/root.zig");
const semantic = icon_component.semantic;

/// Degrees per second the glyph advances.
pub const degrees_per_second: f32 = 300.0;

/// The scratch size: the largest bundled Lucide icon fits several times over.
pub const buffer_size = 2048;

/// Write `svg` with a rotation group around its body into `out`, returning the
/// written slice, or `null` when the source is malformed or `out` is too small.
///
/// The opening tag is preserved verbatim (so `xmlns`/`viewBox` survive), the
/// Lucide viewBox center `(12, 12)` is the pivot.
pub fn rotatedSvg(svg: []const u8, angle_deg: f32, out: []u8) ?[]const u8 {
    const open_end = std.mem.indexOfScalar(u8, svg, '>') orelse return null;
    const close_start = std.mem.lastIndexOf(u8, svg, "</svg>") orelse return null;
    if (close_start < open_end) return null;
    const body = svg[open_end + 1 .. close_start];

    const head = std.fmt.bufPrint(out, "{s}<g transform=\"rotate({d:.1} 12 12)\">", .{
        svg[0 .. open_end + 1],
        angle_deg,
    }) catch return null;

    const tail = "</g></svg>";
    const total = head.len + body.len + tail.len;
    if (total > out.len) return null;
    @memcpy(out[head.len..][0..body.len], body);
    @memcpy(out[head.len + body.len ..][0..tail.len], tail);
    return out[0..total];
}

/// Default glyph name per pack; resolved lazily because `semantic` is a
/// comptime namespace (a struct default can't call it).
pub fn defaultGlyph() icon_component.Name {
    return semantic.loader;
}

pub const Spinner = struct {
    name: ?icon_component.Name = null,
    size_px: f32 = 16,
    color_value: zui.Color = theme.muted_foreground,
    angle_deg: f32 = 0,
    buffer: [buffer_size]u8 = undefined,
    len: usize = 0,

    pub fn init() Spinner {
        return .{};
    }

    pub fn size(self: Spinner, px: f32) Spinner {
        var copy = self;
        copy.size_px = px;
        return copy;
    }

    pub fn color(self: Spinner, value: zui.Color) Spinner {
        var copy = self;
        copy.color_value = value;
        return copy;
    }

    /// Set an absolute angle (degrees), wrapped into `[0, 360)`.
    pub fn angle(self: Spinner, deg: f32) Spinner {
        var copy = self;
        copy.angle_deg = wrapAngle(deg);
        return copy;
    }

    /// Advance the rotation by `dt_seconds` at [`degrees_per_second`].
    pub fn tick(self: *Spinner, dt_seconds: f32) void {
        self.angle_deg = wrapAngle(self.angle_deg + dt_seconds * degrees_per_second);
    }

    pub fn render(self: *Spinner) zui.Element {
        self.refresh();
        return zui.svg(self.buffer[0..self.len]).size(self.size_px).tint(self.color_value);
    }

    /// Rebuild the rotated glyph for the current angle. If rotation cannot be
    /// applied (malformed icon source), fall back to the raw glyph so the
    /// spinner never renders empty.
    fn refresh(self: *Spinner) void {
        const raw = icon_component.bytes(self.name orelse defaultGlyph());
        if (rotatedSvg(raw, self.angle_deg, self.buffer[0..])) |rotated| {
            self.len = rotated.len;
            return;
        }
        if (raw.len <= self.buffer.len) {
            @memcpy(self.buffer[0..raw.len], raw);
            self.len = raw.len;
        } else {
            self.len = 0;
        }
    }
};

fn wrapAngle(deg: f32) f32 {
    return @mod(deg, 360.0);
}

const std = @import("std");

test "rotatedSvg wraps the body in a rotation group" {
    const svg = "<svg><path d=\"M0 0\"/></svg>";
    var out: [256]u8 = undefined;
    const rotated = rotatedSvg(svg, 90, out[0..]) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings(
        "<svg><g transform=\"rotate(90.0 12 12)\"><path d=\"M0 0\"/></g></svg>",
        rotated,
    );
}

test "rotatedSvg preserves the original opening tag" {
    const svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\"><path/></svg>";
    var out: [256]u8 = undefined;
    const rotated = rotatedSvg(svg, 0, out[0..]) orelse return error.TestUnexpectedResult;
    try std.testing.expect(std.mem.startsWith(u8, rotated, "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\">"));
    try std.testing.expect(std.mem.endsWith(u8, rotated, "</g></svg>"));
    try std.testing.expect(std.mem.indexOf(u8, rotated, "rotate(0.0 12 12)") != null);
}

test "rotatedSvg returns null for a too-small buffer or malformed source" {
    const svg = "<svg><path/></svg>";
    var tiny: [4]u8 = undefined;
    try std.testing.expect(rotatedSvg(svg, 0, tiny[0..]) == null);

    // Large enough for the opening tag + wrapper, but not the whole document.
    var partial: [12]u8 = undefined;
    try std.testing.expect(rotatedSvg(svg, 0, partial[0..]) == null);

    try std.testing.expect(rotatedSvg("not an svg", 0, tiny[0..]) == null);
}

test "tick advances 300 degrees per second and wraps" {
    var spinner = Spinner.init();
    try std.testing.expectEqual(@as(f32, 0), spinner.angle_deg);

    spinner.tick(0.5);
    try std.testing.expectApproxEqAbs(@as(f32, 150), spinner.angle_deg, 0.001);

    // 150 + 300 = 450 -> 90.
    spinner.tick(1.0);
    try std.testing.expectApproxEqAbs(@as(f32, 90), spinner.angle_deg, 0.001);

    // A full turn lands back on zero.
    spinner.tick(0.9);
    try std.testing.expectApproxEqAbs(@as(f32, 0), spinner.angle_deg, 0.001);
}

test "angle wraps negatives and full turns" {
    var spinner = Spinner.init().angle(-10);
    try std.testing.expectApproxEqAbs(@as(f32, 350), spinner.angle_deg, 0.001);
    spinner = spinner.angle(720);
    try std.testing.expectApproxEqAbs(@as(f32, 0), spinner.angle_deg, 0.001);
}
