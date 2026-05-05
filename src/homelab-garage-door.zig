const std = @import("std");
const system = std.os.linux;
const C = @cImport({
    @cInclude("linux/gpio.h");
});

pub const std_options: std.Options = .{ .log_level = .debug };

fn get(fd: std.posix.fd_t) C.gpio_v2_line_values {
    var values = std.mem.zeroes(C.gpio_v2_line_values);
    values.mask = 0b11;

    std.debug.assert(.SUCCESS == std.posix.errno(
        system.ioctl(
            fd,
            C.GPIO_V2_LINE_GET_VALUES_IOCTL,
            @intFromPtr(&values),
        ),
    ));

    return values;
}

fn toggle(io: std.Io, fd: std.posix.fd_t) !void {
    var values = std.mem.zeroes(C.gpio_v2_line_values);
    values.mask = 0b11;

    std.log.debug("setting set pin high", .{});
    values.bits = 0b01;
    std.debug.assert(.SUCCESS == std.posix.errno(
        system.ioctl(
            fd,
            C.GPIO_V2_LINE_SET_VALUES_IOCTL,
            @intFromPtr(&values),
        ),
    ));

    try io.sleep(std.Io.Duration.fromSeconds(1), .boot);

    std.log.debug("setting unset pin high", .{});
    values.bits = 0b10;
    std.debug.assert(.SUCCESS == std.posix.errno(
        system.ioctl(
            fd,
            C.GPIO_V2_LINE_SET_VALUES_IOCTL,
            @intFromPtr(&values),
        ),
    ));

    try io.sleep(std.Io.Duration.fromSeconds(1), .boot);

    std.log.debug("setting both pins low", .{});
    values.bits = 0b00;
    std.debug.assert(.SUCCESS == std.posix.errno(
        system.ioctl(
            fd,
            C.GPIO_V2_LINE_SET_VALUES_IOCTL,
            @intFromPtr(&values),
        ),
    ));
}

fn handleConnection(
    io: std.Io,
    stream: *std.Io.net.Stream,
    fd: std.posix.fd_t,
) !void {
    defer stream.close(io);

    var read_buf: [4096]u8 = undefined;
    var write_buf: [4096]u8 = undefined;

    var stream_reader = stream.reader(io, &read_buf);
    var stream_writer = stream.writer(io, &write_buf);

    var server: std.http.Server = .init(&stream_reader.interface, &stream_writer.interface);
    var request = try server.receiveHead();

    std.log.info("{f} {s}", .{ stream.socket.address, request.head.target });

    if (std.mem.eql(u8, "/", request.head.target)) {
        try request.respond(@embedFile("./garage-door.html"), .{
            .extra_headers = &.{
                .{ .name = "Content-Type", .value = "text/html" },
            },
        });
    } else if (std.mem.eql(u8, "/toggle", request.head.target)) {
        try request.respond("OK", .{});
        try toggle(io, fd);
    } else {
        try request.respond("Not found", .{
            .status = .not_found,
        });
    }
}

pub fn main(init: std.process.Init) !void {
    var args = init.minimal.args.iterate();
    _ = args.next() orelse unreachable;
    const chip = args.next() orelse return error.InvalidArgument;

    // assumes latching relay
    const set_line = try std.fmt.parseInt(u32, args.next() orelse return error.InvalidArgument, 10);
    const unset_line = try std.fmt.parseInt(u32, args.next() orelse return error.InvalidArgument, 10);

    std.log.info(
        "using {s}, set line {} and unset line {}",
        .{ chip, set_line, unset_line },
    );

    const mode: enum { oneshot, server } = if (init.environ_map.get("LISTEN_FDS")) |_| .server else .oneshot;

    const gpiochip = try std.Io.Dir.cwd().openFile(init.io, chip, .{ .mode = .read_only });
    defer gpiochip.close(init.io);

    var line_request = std.mem.zeroes(C.gpio_v2_line_request);
    line_request.offsets[0] = set_line;
    line_request.offsets[1] = unset_line;
    line_request.num_lines = 2;
    line_request.config.flags = C.GPIO_V2_LINE_FLAG_OUTPUT;
    std.mem.copyForwards(u8, &line_request.consumer, "garage-door");

    std.debug.assert(.SUCCESS == std.posix.errno(
        system.ioctl(
            gpiochip.handle,
            C.GPIO_V2_GET_LINE_IOCTL,
            @intFromPtr(&line_request),
        ),
    ));
    std.log.debug("line: {}", .{line_request});

    defer _ = system.close(line_request.fd);

    switch (mode) {
        .oneshot => try toggle(init.io, line_request.fd),
        .server => {
            var server: std.Io.net.Server = .{
                .socket = .{
                    .handle = 3, // socket-activated
                    .address = std.Io.net.IpAddress.parseIp6("::", 0) catch @panic("invalid IPv6 address"),
                },
                .options = void{},
            };

            while (true) {
                var connection = server.accept(init.io) catch |err| {
                    std.log.err("failed to accept connection: {}", .{err});
                    continue;
                };

                handleConnection(
                    init.io,
                    &connection,
                    line_request.fd,
                ) catch |err| {
                    std.log.err("failed to handle connection: {}", .{err});
                    continue;
                };
            }
        },
    }
}
