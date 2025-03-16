const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .os_tag = .windows,
            .cpu_arch = .x86_64,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const win_root_module = b.createModule(.{
        .root_source_file = b.path("src/win_main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zigwin32_dep = b.dependency("zigwin32", .{});
    win_root_module.addImport("zigwin32", zigwin32_dep.module("win32"));

    const win_exe = b.addExecutable(.{
        .name = "handmadehero-zig",
        .root_module = win_root_module,
    });

    b.installArtifact(win_exe);

    const wine_cmd = b.addSystemCommand(&.{"wine"});
    wine_cmd.addArtifactArg(win_exe);
    wine_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        wine_cmd.addArgs(args);
    }
    const wine_step = b.step("wine", "Run the app under wine");
    wine_step.dependOn(&wine_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/win_main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const lldb_cmd = b.addSystemCommand(&.{"lldb"});
    lldb_cmd.addArtifactArg(exe_unit_tests);
    const lldb_step = b.step("debug", "Debug tests under lldb");
    lldb_step.dependOn(&lldb_cmd.step);
}
