const std = @import("std");
const C = @cImport({
    @cInclude("qrencode.h");
});

const paste_rs = std.Uri.parse("https://paste.rs") catch @compileError("invalid URI");
const margin = 2;
const empty = " ";
const lower = "\xe2\x96\x84";
const upper = "\xe2\x96\x80";
const full = "\xe2\x96\x88";

fn writeUTF8Margin(writer: *std.Io.Writer, width: usize) !void {
    var x: usize = 0;
    var y: usize = 0;

    while (y < margin / 2) : (y += 1) {
        while (x < width) : (x += 1) {
            try writer.writeAll(full);
        }
        try writer.writeByte('\n');
    }
}

fn writeUTF8(qrcode: *C.QRcode, writer: *std.Io.Writer) !void {
    const width: usize = @intCast(qrcode.width);
    const realwidth = width + margin * 2;

    try writeUTF8Margin(writer, realwidth);

    var y: usize = 0;
    while (y < width) : (y += 2) {
        const row1 = qrcode.data + y * width;
        const row2 = row1 + width;

        var x: usize = 0;
        while (x < margin) : (x += 1) {
            try writer.writeAll(full);
        }

        x = 0;
        while (x < width) : (x += 1) {
            if (row1[x] & 1 == 1) {
                if (y < width - 1 and row2[x] & 1 == 1) {
                    try writer.writeAll(empty);
                } else {
                    try writer.writeAll(lower);
                }
            } else if (y < width - 1 and row2[x] & 1 == 1) {
                try writer.writeAll(upper);
            } else {
                try writer.writeAll(full);
            }
        }

        x = 0;

        while (x < margin) : (x += 1) {
            try writer.writeAll(full);
        }

        try writer.writeByte('\n');
    }

    try writeUTF8Margin(writer, realwidth);
}

pub fn main() !void {
    var buffer: [1024]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var body: std.Io.Writer.Allocating = .init(allocator);

    var stdin: std.fs.File = .stdin();
    var stdin_reader = stdin.reader(&buffer);
    while (stdin_reader.interface.stream(&body.writer, .unlimited)) |_| {} else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var request = try client.request(.POST, paste_rs, .{});
    defer request.deinit();

    @memset(&buffer, 0);
    try request.sendBodyComplete(body.written());
    var response = try request.receiveHead(&.{});
    var response_reader = response.reader(&buffer);

    const paste_url = try response_reader.takeDelimiterExclusive('\n');

    const qrcode = C.QRcode_encodeString8bit(
        response_reader.buffer[0..paste_url.len :0],
        0,
        C.QR_ECLEVEL_L,
    );
    defer C.QRcode_free(qrcode);

    var stdout: std.fs.File = .stdout();
    var stdout_writer = stdout.writer(&.{});
    defer stdout_writer.interface.flush() catch {};

    try stdout_writer.interface.print("{s}\n", .{paste_url});

    try writeUTF8(qrcode, &stdout_writer.interface);
}
