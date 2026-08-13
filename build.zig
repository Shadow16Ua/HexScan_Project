const std = @import("std");
const Config = @import("config.zig");
var options: ?ResolvedOptions = null;

const ResolvedOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

fn resolveOptions(b: *std.Build) ResolvedOptions {
    return .{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.option(std.builtin.OptimizeMode, "Optimize", "Select mode which will be used to compile an executable") orelse Config.optimize,
    };
}

pub fn build(b: *std.Build) !void {
    options = resolveOptions(b);
    const opts = options.?;

    const Lib = b.addLibrary(.{
        .name = "HexScan_Backend",
        .root_module = b.addModule("", .{
            .root_source_file = b.path("src/main.zig"),
            .target = opts.target,
            .optimize = opts.optimize,
        }),
        .linkage = .static,
    });
    b.installArtifact(Lib);
}
