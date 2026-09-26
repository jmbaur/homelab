const std = @import("std");

const Tool = struct {
    name: []const u8,
    link_libc: bool = false,
    linux_only: bool = false,
    link: ?*const fn (*std.Build, *std.Build.Module) void = null,
};

const tools = [_]Tool{
    .{ .name = "copy" },
    .{ .name = "homelab-backup-recv" },
    .{ .name = "homelab-garage-door", .link_libc = true, .linux_only = true },
    .{ .name = "macgen" },
    .{ .name = "networkd-dhcpv6-client-prefix" },
    .{ .name = "nix-key", .link_libc = true, .link = linkLibsodium },
    .{ .name = "nixos-kexec", .linux_only = true },
    .{ .name = "pb", .link_libc = true, .link = linkLibqrencode },
    .{ .name = "pomo" },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // used by nixpkgs' separateDebugInfo
    b.build_id = .sha1;

    // Lets each tool be packaged separately; builds all tools when unset.
    const only = b.option([]const u8, "tool", "Only build and test this tool");

    if (only) |name| {
        for (tools) |tool| {
            if (std.mem.eql(u8, tool.name, name)) break;
        } else return error.UnknownTool;
    }

    const test_step = b.step("test", "Run unit tests");

    for (tools) |tool| {
        if (only) |name| if (!std.mem.eql(u8, tool.name, name)) continue;
        if (tool.linux_only and target.result.os.tag != .linux) continue;

        const module = b.createModule(.{
            .root_source_file = b.path(b.fmt("src/{s}.zig", .{tool.name})),
            .target = target,
            .optimize = optimize,
            .strip = false,
            .link_libc = tool.link_libc,
        });
        if (tool.link) |link| link(b, module);

        b.installArtifact(b.addExecutable(.{ .name = tool.name, .root_module = module }));
        test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = module })).step);
    }
}

fn linkLibsodium(b: *std.Build, module: *std.Build.Module) void {
    const dep = b.lazyDependency("libsodium", .{
        .target = module.resolved_target.?,
        .optimize = module.optimize.?,
        .shared = false,
    }) orelse return;
    module.linkLibrary(dep.artifact("sodium"));
}

fn linkLibqrencode(b: *std.Build, module: *std.Build.Module) void {
    const dep = b.lazyDependency("libqrencode", .{}) orelse return;

    const lib = b.addLibrary(.{
        .name = "qrencode",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = module.resolved_target.?,
            .optimize = module.optimize.?,
            .link_libc = true,
        }),
    });
    lib.root_module.addCSourceFiles(.{
        .root = dep.path(""),
        .flags = &.{
            "-DMAJOR_VERSION=4",
            "-DMINOR_VERSION=1",
            "-DMICRO_VERSION=1",
            "-DVERSION=\"4.1.1\"",
            "-DHAVE_SDL=0",
            "-DSTATIC_IN_RELEASE=static",
        },
        .files = &.{
            "qrencode.c",
            "qrinput.c",
            "bitstream.c",
            "qrspec.c",
            "rsecc.c",
            "split.c",
            "mask.c",
            "mqrspec.c",
            "mmask.c",
        },
    });
    lib.root_module.addIncludePath(dep.path(""));
    lib.installHeadersDirectory(dep.path(""), "", .{});
    module.linkLibrary(lib);
}
