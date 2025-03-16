const std = @import("std");

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));

    var buf = [_]u8{0} ** 6;
    prng.fill(&buf);

    const stdout = std.io.getStdOut().writer();

    for (0..6) |i| {
        try stdout.print("{x:0>2}", .{buf[i]});
        if (i != 5) {
            try stdout.writeByte(':');
        }
    }
}
