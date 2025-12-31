const std = @import("std");

const Prefix = struct {
    Prefix: [16]u8,
    PrefixLength: u8,

    pub fn format(self: @This(), w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print("{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}/{}", .{
            (@as(u16, self.Prefix[0]) << 8) | @as(u16, self.Prefix[1]),
            (@as(u16, self.Prefix[2]) << 8) | @as(u16, self.Prefix[3]),
            (@as(u16, self.Prefix[4]) << 8) | @as(u16, self.Prefix[5]),
            (@as(u16, self.Prefix[6]) << 8) | @as(u16, self.Prefix[7]),
            (@as(u16, self.Prefix[8]) << 8) | @as(u16, self.Prefix[9]),
            (@as(u16, self.Prefix[10]) << 8) | @as(u16, self.Prefix[11]),
            (@as(u16, self.Prefix[12]) << 8) | @as(u16, self.Prefix[13]),
            (@as(u16, self.Prefix[14]) << 8) | @as(u16, self.Prefix[15]),
            self.PrefixLength,
        });
    }
};

const DHCPv6Client = struct {
    Prefixes: []Prefix,
};

const NetworkdStatus = struct {
    DHCPv6Client: DHCPv6Client,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var buf = [_]u8{0} ** 4096;

    var stdin_file = std.fs.File.stdin().reader(&buf);

    var json_reader: std.json.Scanner.Reader = .init(arena.allocator(), &stdin_file.interface);

    const status = try std.json.parseFromTokenSource(NetworkdStatus, arena.allocator(), &json_reader, .{
        .ignore_unknown_fields = true,
    });

    const value: NetworkdStatus = status.value;

    var stdout_file = std.fs.File.stdout().writer(&.{});
    var stdout = &stdout_file.interface;
    for (value.DHCPv6Client.Prefixes) |prefix| {
        try stdout.print("{f}\n", .{prefix});
    }
    try stdout.flush();
}
