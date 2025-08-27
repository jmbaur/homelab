const std = @import("std");

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));

    var buf = [_]u8{0} ** 6;
    prng.fill(&buf);

    var out_buf = [_]u8{0} ** 32;
    var stdout_file = std.fs.File.stdout().writer(&out_buf);
    var stdout = &stdout_file.interface;

    for (0..6) |i| {
        try stdout.print("{x:0>2}", .{buf[i]});
        if (i != 5) {
            try stdout.writeByte(':');
        }
    }

    try stdout.flush();
}
