const std = @import("std");

var inside_tmux = false;

var out_buf: [1024]u8 = undefined;

fn notify(io: std.Io, message: []const u8) !void {
    var stdout_file = std.Io.File.stdout().writer(io, &out_buf);
    var stdout = &stdout_file.interface;
    try stdout.print("{s}\n", .{message});

    if (inside_tmux) {
        try stdout.writeAll("\x1bPtmux;\x1b");
    }

    try stdout.print("\x1b]777;notify;pomodoro;{s}\x1b\x5c", .{message});

    if (inside_tmux) {
        try stdout.writeAll("\x1b\\");
    }

    try stdout.writeAll("\x07"); // bell
    try stdout.flush();
}

fn pomo(
    io: std.Io,
    message: []const u8,
    duration: comptime_int,
) !void {
    var stdout_file = std.Io.File.stdout().writer(io, &out_buf);
    var stdout = &stdout_file.interface;
    try stdout.writeAll("\x1b[2J\x1b[0;0H");
    try stdout.flush();
    try notify(io, message);

    const warning_time_ns = @min(duration / 10, 30 * std.time.ns_per_s);

    var msg_buf = [_]u8{0} ** 30;
    const msg = try std.fmt.bufPrint(&msg_buf, "{}s left!", .{@divFloor(warning_time_ns, std.time.ns_per_s)});

    try io.sleep(std.Io.Duration.fromNanoseconds(duration - warning_time_ns), .boot);
    try notify(io, msg);
    try io.sleep(std.Io.Duration.fromNanoseconds(warning_time_ns), .boot);
}

pub fn main(init: std.process.Init) !void {
    var stdin_file = std.Io.File.stdin().reader(init.io, &.{});

    inside_tmux = init.environ_map.get("TMUX") != null;

    while (true) {
        for (0..4) |_| {
            try pomo(init.io, "work!", 25 * std.time.ns_per_min);
            try pomo(init.io, "break!", 5 * std.time.ns_per_min);
        }

        try pomo(init.io, "long break!", 30 * std.time.ns_per_min);

        std.debug.print(
            "Press <ENTER> to continue to the next pomodoro session, CTRL-C to quit.",
            .{},
        );

        // We don't have the controlling terminal in raw mode, so input will
        // be buffered until a newline is entered. This means if we succeed to
        // read anything, then the user hit <ENTER>.
        _ = try stdin_file.interface.takeByte();
    }
}
