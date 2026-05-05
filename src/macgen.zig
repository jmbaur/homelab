const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var buf: [6]u8 = undefined;
    init.io.random(&buf);

    var out_buf = [_]u8{0} ** 32;
    var stdout_file = std.Io.File.stdout().writer(init.io, &out_buf);
    var stdout = &stdout_file.interface;

    for (0..6) |i| {
        try stdout.print("{x:0>2}", .{buf[i]});
        if (i != 5) {
            try stdout.writeByte(':');
        }
    }

    try stdout.flush();
}
