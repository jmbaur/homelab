const std = @import("std");
const C = @cImport({
    @cInclude("qrencode.h");
});

const paste_host = "https://paste.jmbaur.com";
const paste_uri = std.Uri.parse(paste_host) catch @compileError("invalid URI");
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

pub fn main(init: std.process.Init) !void {
    var buffer: [1024]u8 = undefined;

    const allocator = init.arena.allocator();

    var stdin: std.Io.File = .stdin();
    var stdin_reader = stdin.reader(init.io, &buffer);
    const body = try stdin_reader.interface.allocRemaining(allocator, .unlimited);

    var client: std.http.Client = .{ .io = init.io, .allocator = allocator };
    defer client.deinit();

    const payload = try std.json.Stringify.valueAlloc(allocator, .{ .text = body }, .{});

    var request = try client.request(.POST, paste_uri, .{
        .headers = .{
            .content_type = .{ .override = "application/json" },
            .accept_encoding = .omit,
        },
    });
    defer request.deinit();

    try request.sendBodyComplete(payload);
    var response = try request.receiveHead(&.{});
    if (response.head.status != .ok) {
        std.log.err("paste failed: {d} {s}", .{ @intFromEnum(response.head.status), response.head.reason });
        return error.PasteFailed;
    }

    const response_body = try response.reader(&buffer).allocRemaining(allocator, .unlimited);
    const parsed = try std.json.parseFromSliceLeaky(
        struct { path: []const u8 },
        allocator,
        response_body,
        .{ .ignore_unknown_fields = true },
    );

    const paste_url = try std.fmt.allocPrintSentinel(allocator, paste_host ++ "/raw{s}", .{parsed.path}, 0);

    const qrcode = C.QRcode_encodeString8bit(paste_url, 0, C.QR_ECLEVEL_L);
    defer C.QRcode_free(qrcode);

    var stdout: std.Io.File = .stdout();
    var stdout_writer = stdout.writer(init.io, &.{});
    defer stdout_writer.interface.flush() catch {};

    try stdout_writer.interface.print("{s}\n", .{paste_url});

    try writeUTF8(qrcode, &stdout_writer.interface);
}
