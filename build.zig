const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libsodium_dep = b.dependency("libsodium", .{ .target = target, .optimize = optimize, .shared = false });
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
            .root_source_file = b.path("src/pb.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = true,
        }),
    });
    pb.root_module.linkLibrary(libqrencode);
    b.installArtifact(pb);

    const copy = b.addExecutable(.{
        .name = "copy",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/copy.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = false,
        }),
    });
    b.installArtifact(copy);

    const macgen = b.addExecutable(.{
        .name = "macgen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/macgen.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = false,
        }),
    });
    b.installArtifact(macgen);

    const pomo = b.addExecutable(.{
        .name = "pomo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/pomo.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = false,
        }),
    });
    b.installArtifact(pomo);

    const swayzbar = b.addExecutable(.{
        .name = "swayzbar",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/swayzbar.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = true,
        }),
    });
    b.installArtifact(swayzbar);

    const nixos_kexec = b.addExecutable(.{
        .name = "nixos-kexec",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/nixos-kexec.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = false,
        }),
    });
    b.installArtifact(nixos_kexec);

    const homelab_garage_door = b.addExecutable(.{
        .name = "homelab-garage-door",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/homelab-garage-door.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = true,
        }),
    });
    b.installArtifact(homelab_garage_door);

    const homelab_backup_recv = b.addExecutable(.{
        .name = "homelab-backup-recv",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/homelab-backup-recv.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = false,
        }),
    });
    b.installArtifact(homelab_backup_recv);

    const networkd_dhcpv6_client_prefix = b.addExecutable(.{
        .name = "networkd-dhcpv6-client-prefix",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/networkd-dhcpv6-client-prefix.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = false,
        }),
    });
    b.installArtifact(networkd_dhcpv6_client_prefix);

    const nix_key = b.addExecutable(.{
        .name = "nix-key",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/nix-key.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .link_libc = true,
        }),
    });
    nix_key.root_module.linkLibrary(libsodium_dep.artifact("sodium"));
    b.installArtifact(nix_key);

    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = false,
        }),
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);
}
