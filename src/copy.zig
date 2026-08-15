const std = @import("std");

const encoder = std.base64.standard.Encoder;

pub fn main(init: std.process.Init) !void {
    var in_buf: [1024]u8 = @splat(0);
    var out_buf: [1024]u8 = @splat(0);

    var stdout_file = std.Io.File.stdout().writer(init.io, &out_buf);
    var stdout = &stdout_file.interface;

    var stdin_file = std.Io.File.stdin().reader(init.io, &in_buf);
    var stdin = &stdin_file.interface;

    var input: std.Io.Writer.Allocating = .init(init.arena.allocator());

    while (true) {
        const n_bytes = stdin.stream(&input.writer, .unlimited) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        _ = n_bytes;
    }

    const in_tmux = init.environ_map.get("TMUX") != null;
    if (in_tmux) {
        try stdout.writeAll("\x1bPtmux;\x1b");
    }

    try stdout.writeAll("\x1b]52;c;");
    try std.base64.standard.Encoder.encodeWriter(stdout, input.written());
    try stdout.writeAll("\x07");

    if (in_tmux) {
        try stdout.writeAll("\x1b\\");
    }

    try stdout.flush();
}
