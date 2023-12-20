const std = @import("std");

const Error = error{
    NixStoreNotFound,
};

fn get_nix_store_param(contents: []const u8) ?[]const u8 {
    var cmdline_split = std.mem.split(u8, contents, " ");

    while (cmdline_split.next()) |next| {
        var param_split = std.mem.split(u8, next, "=");
        const key = param_split.next().?;
        const value = param_split.next() orelse continue;

        if (std.mem.eql(u8, key, "nixos.nix_store")) {
            return value;
        }
    }

    return null;
}

test "parse /proc/cmdline" {
    try std.testing.expectEqual(get_nix_store_param("foo=bar bar=baz"), null);
    try std.testing.expectEqualStrings(get_nix_store_param("foo=bar nixos.nix_store=asdf").?, "asdf");
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    var proc_cmdline = try std.fs.openFileAbsolute("/proc/cmdline", .{});
    defer proc_cmdline.close();

    const proc_cmdline_contents = try proc_cmdline.readToEndAlloc(alloc, 4096);

    if (get_nix_store_param(proc_cmdline_contents)) |nix_store_param| {
        const path = try std.fs.path.join(alloc, &.{ std.fs.path.sep_str, "dev", "disk", "by-partlabel", nix_store_param });
        try std.os.symlink(path, "/dev/nixos");
    } else {
        return Error.NixStoreNotFound;
    }
}
