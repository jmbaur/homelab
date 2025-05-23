const std = @import("std");

fn usage(program_name: []const u8) noreturn {
    std.io.getStdErr().writer().print(
        \\usage:
        \\{s}: <peer-file> <snapshot-root>
    , .{program_name}) catch unreachable;

    std.process.exit(1);
}

const Peers = std.AutoHashMap(std.net.Ip6Address, []const u8);

fn parse_peers(allocator: std.mem.Allocator, file_contents: []const u8) !Peers {
    var peers = Peers.init(allocator);
    errdefer peers.deinit();

    var split = std.mem.splitSequence(u8, file_contents, "\n");

    while (split.next()) |line| {
        if (std.mem.eql(u8, line, "")) {
            continue;
        }

        var line_split = std.mem.splitSequence(u8, line, " ");

        const name = line_split.next() orelse {
            std.log.err("invalid line '{s}'", .{line});
            continue;
        };

        const ip_string = line_split.next() orelse {
            std.log.err("invalid line '{s}'", .{line});
            continue;
        };

        const ip = std.net.Ip6Address.parse(ip_string, 0) catch {
            std.log.err("invalid line '{s}'", .{line});
            continue;
        };

        try peers.put(ip, name);
    }

    return peers;
}

test {
    var peers = try parse_peers(std.testing.allocator,
        \\foo 2001:db8::1
        \\bar 2001:db8::2
    );
    defer peers.deinit();

    try std.testing.expectEqual(2, peers.count());
    try std.testing.expectEqualStrings(
        "foo",
        peers.get(try std.net.Ip6Address.parse("2001:db8::1", 0)).?,
    );

    try std.testing.expectEqualStrings(
        "bar",
        peers.get(try std.net.Ip6Address.parse("2001:db8::2", 0)).?,
    );
}

fn handle_connection(
    allocator: std.mem.Allocator,
    connection: std.net.Server.Connection,
    peers: Peers,
    snapshot_root: []const u8,
) !void {
    defer connection.stream.close();

    var address = connection.address;
    address.setPort(0);

    const peer_name = peers.get(address.in6) orelse {
        std.log.warn("address {} not found in peers", .{connection.address});
        return;
    };

    const snapshot_path = try std.fs.path.join(
        allocator,
        &.{ snapshot_root, peer_name },
    );
    defer allocator.free(snapshot_path);

    std.fs.cwd().access(snapshot_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            try std.fs.cwd().makePath(snapshot_path);
        },
        else => return err,
    };

    var child = std.process.Child.init(
        &.{ "btrfs", "receive", "-e", snapshot_path },
        allocator,
    );

    child.stdin_behavior = .Pipe;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    try child.spawn();

    const child_stdin = child.stdin orelse {
        std.log.err("btrfs child process stdin not available", .{});
        return;
    };

    const reader = connection.stream.reader();
    const writer = child_stdin.writer();

    var buf: [4096]u8 = undefined;

    var total_bytes: u64 = 0;
    while (true) {
        const bytes_read = try reader.read(&buf); //  catch |err| switch (err) {};
        if (bytes_read == 0) {
            break;
        }

        total_bytes += bytes_read;

        try writer.writeAll(buf[0..bytes_read]);
    }

    const term = try child.wait();

    switch (term.Exited) {
        0 => std.log.info("finished backup for peer {s} (received {:.2})", .{ peer_name, std.fmt.fmtIntSizeDec(total_bytes) }),
        else => |status| std.log.err("failed to backup peer {s} (btrfs exited with status {})", .{ peer_name, status }),
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer {
        _ = gpa.deinit();
    }

    var args = try std.process.argsWithAllocator(gpa.allocator());
    defer args.deinit();

    const program_name = args.next() orelse unreachable;
    const peer_filepath = args.next() orelse return usage(program_name);
    const snapshot_root = args.next() orelse return usage(program_name);
    const port = std.fmt.parseInt(
        u16,
        args.next() orelse return usage(program_name),
        10,
    ) catch {
        return usage(program_name);
    };

    var peer_file = try std.fs.cwd().openFile(peer_filepath, .{});
    defer peer_file.close();

    const peer_file_contents = try peer_file.readToEndAlloc(
        gpa.allocator(),
        4096,
    );
    defer gpa.allocator().free(peer_file_contents);

    var peers = try parse_peers(gpa.allocator(), peer_file_contents);
    defer peers.deinit();

    var iter = peers.iterator();
    while (iter.next()) |peer| {
        std.log.info(
            "using peer '{s}' at {}",
            .{ peer.value_ptr.*, peer.key_ptr.* },
        );
    }

    const bind_address = try std.net.Address.parseIp("::", port);

    var server = try bind_address.listen(.{});
    defer server.deinit();

    while (true) {
        var handle = try std.Thread.spawn(
            .{},
            handle_connection,
            .{ gpa.allocator(), try server.accept(), peers, snapshot_root },
        );
        handle.detach();
    }
}
