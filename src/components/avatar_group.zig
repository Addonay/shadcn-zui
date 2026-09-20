//! AvatarGroup — an overlapping stack of avatars (gpui-kit's `avatar_group`).
//!
//! Overlap needs negative margins, which zui lacks — so the stack lays the
//! avatars out absolutely with a fixed step inside a wrapper sized for it.
//! Optional trailing "+N" overflow pill (caller-owned text).

const zui = @import("zui");

const avatar_component = @import("avatar.zig");
const theme = @import("../theme.zig");

pub const default_step: f32 = 24;
pub const default_avatar_px: f32 = 32;

pub const AvatarGroup = struct {
    /// Caller-owned names; letters borrow from them at paint time.
    names: []const []const u8,
    /// How many avatars to show (rest are dropped).
    max_shown: usize = 4,
    step_px: f32 = default_step,
    avatar_px: f32 = default_avatar_px,

    pub fn init(names: []const []const u8) AvatarGroup {
        return .{ .names = names };
    }

    pub fn maxShown(self: AvatarGroup, value: usize) AvatarGroup {
        var copy = self;
        copy.max_shown = value;
        return copy;
    }

    pub fn step(self: AvatarGroup, px: f32) AvatarGroup {
        var copy = self;
        copy.step_px = px;
        return copy;
    }

    /// Total width of the stack (pure; unit-tested).
    pub fn width(self: AvatarGroup) f32 {
        const shown = @min(self.max_shown, self.names.len);
        if (shown == 0) return 0;
        return self.step_px * (@as(f32, @floatFromInt(shown)) - 1) + self.avatar_px;
    }

    pub fn render(self: AvatarGroup) zui.Element {
        var group = zui.div().w(self.width()).h(self.avatar_px);
        const shown = @min(self.max_shown, self.names.len);
        for (self.names[0..shown], 0..) |name, index| {
            const offset = @as(f32, @floatFromInt(index)) * self.step_px;
            group = group.child(zui.div().absolute().left(offset).top(0)
                .child(avatar_component.Avatar.init(name).sizePx(self.avatar_px).render()));
        }
        return group;
    }
};

const std = @import("std");

test "width grows by step and covers the last avatar" {
    var names = [_][]const u8{ "Ann", "Bob", "Cid" };
    const group = AvatarGroup.init(&names).maxShown(3);
    try std.testing.expectApproxEqAbs(24 * 2 + 32, group.width(), 0.001);
}

test "max shown clamps to members" {
    var names = [_][]const u8{ "Ann", "Bob" };
    const group = AvatarGroup.init(&names).maxShown(5);
    try std.testing.expectApproxEqAbs(24 * 1 + 32, group.width(), 0.001);
}
