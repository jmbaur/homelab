const std = @import("std");
const C = @cImport({
    @cInclude("linux/gpio.h");
});

pub const std_options: std.Options = .{ .log_level = .debug };

const button =
    \\<!DOCTYPE html>
    \\<html>
    \\<head>
    \\<title>Garage Door</title>
    \\<script>function toggle() { fetch("/toggle"); }</script>
    \\</head>
    \\<button type="submit" onclick="toggle()">Toggle</button> 
    \\</html>
;

fn get(fd: std.posix.fd_t) C.gpio_v2_line_values {
    var values = std.mem.zeroes(C.gpio_v2_line_values);
    values.mask = 0b11;

    std.debug.assert(.SUCCESS == std.posix.errno(
        std.os.linux.ioctl(
            fd,
            C.GPIO_V2_LINE_GET_VALUES_IOCTL,
            @intFromPtr(&values),
        ),
    ));

    return values;
}

fn toggle(fd: std.posix.fd_t) !void {
    var values = std.mem.zeroes(C.gpio_v2_line_values);
    values.mask = 0b11;

    std.log.debug("before: {}", .{get(fd)});

    // set line high, unset line low
    values.bits = 0b01;
    std.debug.assert(.SUCCESS == std.posix.errno(
        std.os.linux.ioctl(
            fd,
            C.GPIO_V2_LINE_SET_VALUES_IOCTL,
            @intFromPtr(&values),
        ),
    ));

    std.Thread.sleep(std.time.ns_per_s);

    std.log.debug("after set line high, unset line low: {}", .{get(fd)});

    // unset line high, set line low
    values.bits = 0b10;
    std.debug.assert(.SUCCESS == std.posix.errno(
        std.os.linux.ioctl(
            fd,
            C.GPIO_V2_LINE_SET_VALUES_IOCTL,
            @intFromPtr(&values),
        ),
    ));

    std.Thread.sleep(std.time.ns_per_s);

    std.log.debug("after set line low, unset line high: {}", .{get(fd)});

    // both lines low
    values.bits = 0b00;
    std.debug.assert(.SUCCESS == std.posix.errno(
        std.os.linux.ioctl(
            fd,
            C.GPIO_V2_LINE_SET_VALUES_IOCTL,
            @intFromPtr(&values),
        ),
    ));

    std.log.debug("after set line low, unset line low: {}", .{get(fd)});
}

fn handleConnection(
    connection: *std.net.Server.Connection,
    fd: std.posix.fd_t,
) !void {
    defer connection.stream.close();

    var read_buf = [_]u8{0} ** 1024;
    var write_buf = [_]u8{0} ** 1024;

    var stream_reader = connection.stream.reader(&read_buf);
    var stream_writer = connection.stream.writer(&write_buf);

    var server: std.http.Server = .init(stream_reader.interface(), &stream_writer.interface);
    var request = try server.receiveHead();

    std.log.info("{f} {s}", .{ connection.address, request.head.target });

    if (std.mem.eql(u8, "/", request.head.target)) {
        try request.respond(button, .{
            .extra_headers = &.{
                .{ .name = "Content-Type", .value = "text/html" },
            },
        });
    } else if (std.mem.eql(u8, "/toggle", request.head.target)) {
        try request.respond("OK", .{});
        try toggle(fd);
    } else {
        try request.respond("Not found", .{
            .status = .not_found,
        });
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next() orelse unreachable;
    const chip = args.next() orelse return error.InvalidArgument;

    // assumes latching relay
    const set_line = try std.fmt.parseInt(u32, args.next() orelse return error.InvalidArgument, 10);
    const unset_line = try std.fmt.parseInt(u32, args.next() orelse return error.InvalidArgument, 10);

    std.log.info(
        "using {s}, set line {} and unset line {}",
        .{ chip, set_line, unset_line },
    );

    const env = try std.process.getEnvMap(allocator);
    const mode: enum { oneshot, server } = if (env.get("LISTEN_FDS")) |_| .server else .oneshot;

    const gpiochip = try std.fs.cwd().openFile(chip, .{ .mode = .read_only });
    defer gpiochip.close();

    var line_request = std.mem.zeroes(C.gpio_v2_line_request);
    line_request.offsets[0] = set_line;
    line_request.offsets[1] = unset_line;
    line_request.num_lines = 2;
    line_request.config.flags = C.GPIO_V2_LINE_FLAG_OUTPUT;
    std.mem.copyForwards(u8, &line_request.consumer, "garage-door");

    std.debug.assert(.SUCCESS == std.posix.errno(
        std.os.linux.ioctl(
            gpiochip.handle,
            C.GPIO_V2_GET_LINE_IOCTL,
            @intFromPtr(&line_request),
        ),
    ));
    std.log.debug("line: {}", .{line_request});

    defer std.posix.close(line_request.fd);

    switch (mode) {
        .oneshot => try toggle(line_request.fd),
        .server => {
            const listen_address: std.net.Ip6Address = .init([_]u8{0} ** 16, 0, 0, 0);
            var server: std.net.Server = .{
                .listen_address = .{ .in6 = listen_address },
                .stream = .{ .handle = 3 },
            };

            while (true) {
                var connection = server.accept() catch |err| {
                    std.log.err("failed to accept connection: {}", .{err});
                    continue;
                };

                handleConnection(
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
