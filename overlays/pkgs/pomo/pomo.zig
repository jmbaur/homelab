const std = @import("std");

const thirty_seconds = 30 * std.time.ns_per_s;

var inside_tmux = false;

fn notify(message: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{message});

    if (inside_tmux) {
        try stdout.writeAll("\x1bPtmux;\x1b");
    }

    try stdout.print("\x1b]777;notify;pomodoro;{s}\x1b\x5c", .{message});

    if (inside_tmux) {
        try stdout.writeAll("\x1b\\");
    }

    try stdout.writeAll("\x07"); // bell
}

fn pomo(
    message: []const u8,
    duration: comptime_int,
) !void {
    if (duration < thirty_seconds) {
        @compileError("duration too short");
    }

    try std.io.getStdOut().writer().writeAll("\x1b[2J\x1b[0;0H");
    try notify(message);

    std.Thread.sleep(duration - thirty_seconds);
    try notify("30 seconds left!");
    std.Thread.sleep(thirty_seconds);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

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
        _ = try std.io.getStdIn().reader().readByte();
    }
}
