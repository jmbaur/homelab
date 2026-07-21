const std = @import("std");

const encoder = std.base64.standard.Encoder;

pub fn main(init: std.process.Init) !void {
    var in_buf = [_]u8{0} ** 1024;
    var out_buf = [_]u8{0} ** 1024;

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

    try stdout.writeAll("\x1b]52;c;");
    try std.base64.standard.Encoder.encodeWriter(stdout, input.written());
    try stdout.writeAll("\x07");
    try stdout.flush();
}
