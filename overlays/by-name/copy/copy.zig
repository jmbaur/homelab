const std = @import("std");

const encoder = std.base64.standard.Encoder;

pub fn main() !void {
    var buffered_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer buffered_writer.flush() catch {};

    const writer = buffered_writer.writer();

    try writer.writeAll("\x1b]52;c;");
    try encoder.encodeFromReaderToWriter(writer, std.io.getStdIn().reader());
    try writer.writeAll("\x07");
}
