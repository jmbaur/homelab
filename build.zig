const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libqrencode_dep = b.dependency("libqrencode", .{});

    const libqrencode = b.addLibrary(.{
        .name = "qrencode",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    libqrencode.root_module.addCSourceFiles(.{
        .root = libqrencode_dep.path(""),
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
    libqrencode.root_module.addIncludePath(libqrencode_dep.path(""));
    libqrencode.installHeadersDirectory(libqrencode_dep.path(""), "", .{});

    const pb = b.addExecutable(.{
        .name = "pb",
        .root_module = b.createModule(.{
            .root_source_file = b.path("pb.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = true,
        }),
    });
    pb.root_module.linkLibrary(libqrencode);

    b.installArtifact(pb);
}
