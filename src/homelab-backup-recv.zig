const std = @import("std");

fn usage(program_name: []const u8) noreturn {
    std.debug.print(
        \\usage:
        \\{s}: <peer-file> <snapshot-root>
    , .{program_name});

    std.process.exit(1);
}

const Peers = std.array_hash_map.Auto(std.Io.net.Ip6Address, []const u8);

fn parsePeers(arena: std.mem.Allocator, reader: *std.Io.Reader) !Peers {
    var peers: Peers = .empty;
    errdefer peers.deinit(arena);

    var line_buf: [1024]u8 = undefined;
    var line_writer: std.Io.Writer = .fixed(&line_buf);

    while (true) {
        defer _ = line_writer.consumeAll();

        const written = b: {
            if (reader.streamDelimiter(&line_writer, '\n')) |written| {
                reader.toss(1);
                break :b written;
            } else |err| switch (err) {
                error.EndOfStream => break :b 0,
                else => return err,
            }
        };

        const line = line_writer.buffer[0..line_writer.end];
        if (line.len == 0 and written == 0) {
            break;
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

        const ip = std.Io.net.Ip6Address.parse(ip_string, 0) catch {
            std.log.err("invalid line '{s}'", .{line});
            continue;
        };

        try peers.put(arena, ip, try arena.dupe(u8, name));

        if (written == 0) break;
    }

    return peers;
}

fn assertParsePeers(allocator: std.mem.Allocator, peers_content: []const u8) !void {
    var peer_reader = std.Io.Reader.fixed(peers_content);
    var peers = try parsePeers(allocator, &peer_reader);

    try std.testing.expectEqual(2, peers.count());
    try std.testing.expectEqualStrings(
        "foo",
        peers.get(try std.Io.net.Ip6Address.parse("2001:db8::1", 0)).?,
    );

    try std.testing.expectEqualStrings(
        "bar",
        peers.get(try std.Io.net.Ip6Address.parse("2001:db8::2", 0)).?,
    );
}

test parsePeers {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();

    const fixed_peers =
        \\foo 2001:db8::1
        \\bar 2001:db8::2
    ;
    try assertParsePeers(arena.allocator(), fixed_peers);

    const fixed_peers_with_newline = fixed_peers ++ "\n";
    try assertParsePeers(arena.allocator(), fixed_peers_with_newline);
}

fn handleConnection(
    io: std.Io,
    allocator: std.mem.Allocator,
    stream: std.Io.net.Stream,
    peers: Peers,
    snapshot_root: []const u8,
) !void {
    var reader_buf: [4096]u8 = undefined;
    var writer_buf: [4096]u8 = undefined;

    defer stream.close(io);

    var address = stream.socket.address;
    address.setPort(0);

    switch (address) {
        .ip4 => {
            std.log.warn("got IPv4 address, skipping", .{});
            return;
        },
        .ip6 => {},
    }

    const peer_name = peers.get(address.ip6) orelse {
        std.log.warn("address {f} not found in peers", .{address});
        return;
    };

    const snapshot_path = try std.fs.path.join(
        allocator,
        &.{ snapshot_root, peer_name },
    );
    defer allocator.free(snapshot_path);

    std.Io.Dir.cwd().access(io, snapshot_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            try std.Io.Dir.cwd().createDirPath(io, snapshot_path);
        },
        else => return err,
    };

    var child = try std.process.spawn(io, .{
        .argv = &.{ "btrfs", "receive", "-e", snapshot_path },
        .stdin = .pipe,
        .stdout = .inherit,
        .stderr = .inherit,
    });

    const child_stdin = child.stdin orelse {
        std.log.err("btrfs child process stdin not available", .{});
        return;
    };

    var stream_reader = stream.reader(io, &reader_buf);
    var child_writer = child_stdin.writer(io, &writer_buf);

    var total_bytes: usize = 0;
    while (stream_reader.interface.stream(&child_writer.interface, .unlimited)) |bytes| {
        total_bytes += bytes;
    } else |err| {
        switch (err) {
            error.EndOfStream => {
                // btrfs-receive requires writing and EOF byte
                try child_writer.interface.writeByte(0);
                try child_writer.interface.flush();
            },
            else => return err,
        }
    }

    const term = try child.wait(io);

    switch (term.exited) {
        0 => std.log.info("finished backup for peer {s} (received {Bi:.2})", .{ peer_name, total_bytes }),
        else => |status| std.log.err("failed to backup peer {s} (btrfs exited with status {})", .{ peer_name, status }),
    }
}

pub fn main(init: std.process.Init) !void {
    var args = init.minimal.args.iterate();
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

    var peer_file = try std.Io.Dir.cwd().openFile(init.io, peer_filepath, .{});
    defer peer_file.close(init.io);

    var buf: [1024]u8 = undefined;
    var reader = peer_file.reader(init.io, &buf);

    var peers = try parsePeers(init.arena.allocator(), &reader.interface);

    var iter = peers.iterator();
    while (iter.next()) |peer| {
        std.log.info(
            "using peer '{s}' at {f}",
            .{ peer.value_ptr.*, peer.key_ptr.* },
        );
    }

    const bind_address = try std.Io.net.IpAddress.parse("::", port);

    var server = try bind_address.listen(init.io, .{});
    defer server.deinit(init.io);

    while (true) {
        var handle = try std.Thread.spawn(
            .{},
            handleConnection,
            .{ init.io, init.gpa, try server.accept(init.io), peers, snapshot_root },
        );
        handle.detach();
    }
}
