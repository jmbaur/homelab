const std = @import("std");

const encoder = std.base64.standard.Encoder;

pub fn main(init: std.process.Init) !void {
    var in_buf = [_]u8{0} ** 4096;
    var out_buf = [_]u8{0} ** 1024;

    var stdout_file = std.Io.File.stdout().writer(init.io, &out_buf);
    var stdout = &stdout_file.interface;

    try stdout.writeAll("\x1b]52;c;");
    var stdin_file = std.Io.File.stdin().reader(init.io, &in_buf);
    var stdin = &stdin_file.interface;
    const input = try stdin.takeDelimiterExclusive(0);
    try std.base64.standard.Encoder.encodeWriter(stdout, input);
    try stdout.writeAll("\x07");
    try stdout.flush();
}
