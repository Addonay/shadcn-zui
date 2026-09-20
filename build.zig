const std = @import("std");

/// Icon pack presets; only the selected pack's assets are embedded.
pub const IconsPreset = enum { lucide, tabler, phosphor, heroicons, hugeicons };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zui_dep = b.dependency("zui", .{ .target = target, .optimize = optimize });
    const zui_mod = zui_dep.module("zui");

    const preset_name = b.option([]const u8, "icons-preset", "Icon pack: lucide|tabler|phosphor|heroicons|hugeicons") orelse "lucide";
    const preset_value = std.meta.stringToEnum(IconsPreset, preset_name) orelse .lucide;
    const icons_options = b.addOptions();
    icons_options.addOption(IconsPreset, "icons_preset", preset_value);

    // The library module apps import as "shadcn-zui".
    const mod = b.addModule("shadcn-zui", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zui", .module = zui_mod }},
    });
    mod.addOptions("build_options", icons_options);

    // Unit tests (component metrics + pure helpers).
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zui", .module = zui_mod }},
        }),
    });
    tests.root_module.addOptions("build_options", icons_options);
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run shadcn-zui unit tests");
    test_step.dependOn(&run_tests.step);

    // Component gallery.
    const gallery = b.addExecutable(.{
        .name = "gallery",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/gallery/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
                .{ .name = "shadcn-zui", .module = mod },
            },
        }),
    });
    b.installArtifact(gallery);
    const run_gallery = b.addRunArtifact(gallery);
    const run_step = b.step("run-gallery", "Run the component gallery");
    run_step.dependOn(&run_gallery.step);

    // Headless snapshot of the gallery, for visual checks.
    const snapshot_width = b.option(u32, "snapshot-width", "Snapshot width in px") orelse 1400;
    const snapshot_height = b.option(u32, "snapshot-height", "Snapshot height in px (make it tall to capture the whole page)") orelse 1000;
    const snapshot = b.addRunArtifact(gallery);
    snapshot.setEnvironmentVariable("ZUI_SNAPSHOT", "/tmp/opencode/shadcn-gallery.ppm");
    snapshot.setEnvironmentVariable("ZUI_SNAPSHOT_WIDTH", b.fmt("{d}", .{snapshot_width}));
    snapshot.setEnvironmentVariable("ZUI_SNAPSHOT_HEIGHT", b.fmt("{d}", .{snapshot_height}));
    const snapshot_step = b.step("snapshot-gallery", "Render the gallery to a PPM snapshot (zig-out/bin/gallery is installed too)");
    snapshot_step.dependOn(&snapshot.step);

    // Headless interaction self-test (clicks every control type).
    const selftest = b.addRunArtifact(gallery);
    selftest.setEnvironmentVariable("ZUI_SELFTEST", "1");
    const selftest_step = b.step("selftest-gallery", "Run the gallery's headless interaction self-test");
    selftest_step.dependOn(&selftest.step);
}
