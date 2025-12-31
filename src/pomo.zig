const std = @import("std");

var inside_tmux = false;

var out_buf = [_]u8{0} ** 1024;
var stdout_file = std.fs.File.stdout().writer(&out_buf);

fn notify(message: []const u8) !void {
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
    message: []const u8,
    duration: comptime_int,
) !void {
    var stdout = &stdout_file.interface;
    try stdout.writeAll("\x1b[2J\x1b[0;0H");
    try stdout.flush();
    try notify(message);

    const warning_time_ns = @min(duration / 10, 30 * std.time.ns_per_s);

    var msg_buf = [_]u8{0} ** 30;
    const msg = try std.fmt.bufPrint(&msg_buf, "{}s left!", .{@divFloor(warning_time_ns, std.time.ns_per_s)});

    std.Thread.sleep(duration - warning_time_ns);
    try notify(msg);
    std.Thread.sleep(warning_time_ns);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var stdin_file = std.fs.File.stdin().reader(&.{});
    var stdin = &stdin_file.interface;

    inside_tmux = b: {
        _ = std.process.getEnvVarOwned(allocator, "TMUX") catch |err| switch (err) {
            error.EnvironmentVariableNotFound => break :b false,
            else => return err,
        };

        break :b true;
    };

    while (true) {
        for (0..4) |_| {
            try pomo("work!", 25 * std.time.ns_per_min);
            try pomo("break!", 5 * std.time.ns_per_min);
        }

        try pomo("long break!", 30 * std.time.ns_per_min);

        std.debug.print(
            "Press <ENTER> to continue to the next pomodoro session, CTRL-C to quit.",
            .{},
        );

        // We don't have the controlling terminal in raw mode, so input will
        // be buffered until a newline is entered. This means if we succeed to
        // read anything, then the user hit <ENTER>.
        _ = try stdin.takeByte();
    }
}
