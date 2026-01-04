const std = @import("std");

const PROFILES_DIR = "/nix/var/nix/profiles";

// NOTE: This is super hacky, but this value differs across libc
// implementations as well as what the kernel itself defines. Since we
// are almost certainly using a systemd built against glibc, we hardcode
// the value.
const SIGRTMIN = 34;

fn chooseToplevelFromGenerations(allocator: std.mem.Allocator) ![]const u8 {
    var buf: [1024]u8 = undefined;
    var stdout = std.fs.File.stdout();
    var writer = stdout.writer(&buf);

    var generations: std.ArrayList([]const u8) = .{};
    defer generations.deinit(allocator);

    var profiles_dir = try std.fs.cwd().openDir(PROFILES_DIR, .{ .iterate = true });
    defer profiles_dir.close();

    var index: usize = 0;

    var iter = profiles_dir.iterate();
    while (try iter.next()) |dir_entry| {
        if (dir_entry.kind == .sym_link and
            std.mem.startsWith(u8, dir_entry.name, "system-") and
            std.mem.endsWith(u8, dir_entry.name, "-link"))
        {
            index += 1;
            try writer.interface.print(
                "{d}: {s}/{s}\n",
                .{ index, PROFILES_DIR, dir_entry.name },
            );
            try generations.append(
                allocator,
                try allocator.dupe(u8, dir_entry.name),
            );
        }
    }

    try writer.interface.print("which generation would you like to kexec? ", .{});
    try writer.interface.flush();

    var stdin = std.fs.File.stdin();
    var reader = stdin.reader(&buf);
    const input = try reader.interface.takeDelimiterExclusive('\n');
    const choice = try std.fmt.parseInt(
        usize,
        std.mem.trim(u8, input, &std.ascii.whitespace),
        10,
    );

    if (choice > generations.items.len) {
        return error.InvalidChoice;
    }

    return try std.fmt.allocPrint(
        allocator,
        "{s}/{s}",
        .{ PROFILES_DIR, generations.items[choice - 1] },
    );
}

const KEXEC_LOADED = "/sys/kernel/kexec_loaded";

fn waitForKexecKernelLoaded() !void {
    var f = try std.fs.cwd().openFile(KEXEC_LOADED, .{});
    defer f.close();

    var buffer: [1]u8 = undefined;
    var reader = f.reader(&buffer);

    var time_slept: usize = 0;
    while (time_slept < 10 * std.time.ns_per_s) : (time_slept += std.time.ns_per_s) {
        std.log.debug("waiting for kexec load to finish", .{});
        try f.seekTo(0);

        if (try reader.interface.takeByte() == '1') {
            return;
        }

        std.Thread.sleep(std.time.ns_per_s);
    }

    return error.Timeout;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var args = std.process.args();
    _ = args.next(); // skip argv[0]

    var toplevel: ?[]const u8 = null;
    var append: ?[]const u8 = null;

    while (args.next()) |arg| {
        if (append == null and std.mem.eql(u8, arg, "--append")) {
            append = args.next() orelse return error.InvalidArg;
        } else if (toplevel == null) {
            toplevel = arg;
        }
    }

    const chosen = try std.fs.cwd().realpathAlloc(allocator, toplevel orelse try chooseToplevelFromGenerations(allocator));
    std.log.info("booting from {s}", .{chosen});
    var toplevel_dir = try std.fs.cwd().openDir(chosen, .{});
    defer toplevel_dir.close();

    var boot_json = try toplevel_dir.openFile("boot.json", .{});
    defer boot_json.close();

    const bootspec = try std.json.parseFromSlice(
        std.json.Value,
        allocator,
        try boot_json.readToEndAlloc(allocator, std.math.maxInt(usize)),
        .{},
    );

    const bootspec_v1 = bootspec.value.object.get("org.nixos.bootspec.v1") orelse return error.MissingBootspecV1;
    const kernel = bootspec_v1.object.get("kernel") orelse return error.MissingKernel;
    const initrd = bootspec_v1.object.get("initrd");
    const init = bootspec_v1.object.get("init");
    const kernel_params = bootspec_v1.object.get("kernelParams") orelse return error.MissingKernel;

    var cmdline: std.Io.Writer.Allocating = .init(allocator);
    try cmdline.writer.print("init={s} ", .{init.?.string});
    for (kernel_params.array.items) |param| {
        try cmdline.writer.writeAll(param.string);
        try cmdline.writer.writeByte(' ');
    }

    if (append) |extra_cmdline| {
        try cmdline.writer.writeAll(std.mem.trim(u8, extra_cmdline, &std.ascii.whitespace));
        try cmdline.writer.writeByte(' ');
    }

    var full_cmdline = cmdline.writer.buffered();
    full_cmdline[full_cmdline.len - 1] = 0; // required by kexec_file_load

    var kernel_file = try std.fs.cwd().openFile(kernel.string, .{});
    defer kernel_file.close();

    const ret = b: {
        if (initrd) |initrd_filepath| {
            var initrd_file = try std.fs.cwd().openFile(initrd_filepath.string, .{});
            defer initrd_file.close();

            break :b std.os.linux.syscall5(
                .kexec_file_load,
                @intCast(kernel_file.handle),
                @intCast(initrd_file.handle),
                full_cmdline.len,
                @intFromPtr(full_cmdline.ptr),
                0,
            );
        } else {
            const NO_INITRAMFS = 4;
            break :b std.os.linux.syscall5(
                .kexec_file_load,
                @intCast(kernel_file.handle),
                0,
                full_cmdline.len,
                @intFromPtr(full_cmdline.ptr),
                NO_INITRAMFS,
            );
        }
    };

    try waitForKexecKernelLoaded();

    switch (std.posix.E.init(ret)) {
        .SUCCESS => {},
        else => |err| {
            std.log.err("kexec failed: {}", .{err});
            return std.posix.unexpectedErrno(err);
        },
    }

    // Same as running systemctl kexec
    switch (std.posix.E.init(std.os.linux.kill(1, SIGRTMIN + 6))) {
        .SUCCESS => {},
        else => |err| {
            std.log.err("kill failed: {}", .{err});
            return std.posix.unexpectedErrno(err);
        },
    }
}
