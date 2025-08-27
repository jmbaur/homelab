// TODO(jared): We are setting an arbitrary limit on the data filesize to 4KiB.

const std = @import("std");

const C = @cImport({
    @cInclude("sodium.h");
});

fn usage(program_name: []const u8) noreturn {
    std.debug.print(
        \\usage:
        \\{0s}: <action> [<arg>...]
        \\
        \\actions:
        \\  sign:
        \\    {0s} sign <data-file> <key-file>
        \\  verify:
        \\    {0s} verify <data-file> <signature-file> [<verify-key>...]
    , .{program_name});

    std.process.exit(1);
}

fn sign(
    allocator: std.mem.Allocator,
    program_name: []const u8,
    args: *std.process.ArgIterator,
) !void {
    const data_filepath = args.next() orelse {
        return usage(program_name);
    };
    const key_filepath = args.next() orelse {
        return usage(program_name);
    };

    const key_file = try std.fs.cwd().openFile(key_filepath, .{});
    defer key_file.close();

    const data_file = try std.fs.cwd().openFile(data_filepath, .{});
    defer data_file.close();

    const key_content = try key_file.readToEndAlloc(allocator, 4096);
    defer allocator.free(key_content);

    var split = std.mem.splitSequence(u8, key_content, ":");

    const key_name = split.next() orelse return usage(program_name);
    const key_base64 = split.next() orelse return usage(program_name);
    if (split.next() != null) {
        return usage(program_name);
    }

    const decoded_size = try std.base64.standard.Decoder.calcSizeForSlice(
        key_base64,
    );

    const key_data = try allocator.alloc(u8, decoded_size);
    defer allocator.free(key_data);

    try std.base64.standard.Decoder.decode(key_data, key_base64);

    const data_content = try data_file.readToEndAlloc(allocator, 4096);
    defer allocator.free(data_content);

    var signature = [_]u8{0} ** C.crypto_sign_BYTES;

    var signature_len: c_ulonglong = 0;

    if (C.sodium_init() != 0) {
        return error.LibsodiumInit;
    }

    if (C.crypto_sign_detached(
        &signature,
        &signature_len,
        data_content.ptr,
        data_content.len,
        key_data.ptr,
    ) != 0) {
        return error.LibsodiumSignDetached;
    }

    if (signature_len != C.crypto_sign_BYTES) {
        return error.InvalidSignature;
    }

    const encoded_size = std.base64.standard.Encoder.calcSize(signature.len);
    const encode_buf = try allocator.alloc(u8, encoded_size);
    defer allocator.free(encode_buf);

    const encoded = std.base64.standard.Encoder.encode(encode_buf, &signature);

    var out_buf = [_]u8{0} ** 1024;
    var stdout_file = std.fs.File.stdout().writer(&out_buf);
    var stdout = &stdout_file.interface;
    try stdout.print("{s}:{s}", .{ key_name, encoded });
    try stdout.flush();
}

fn verify(
    allocator: std.mem.Allocator,
    program_name: []const u8,
    args: *std.process.ArgIterator,
) !void {
    const data_filepath = args.next() orelse return usage(program_name);
    const signature_filepath = args.next() orelse return usage(program_name);

    var keys = std.StringHashMap([]const u8).init(allocator);
    defer keys.deinit();

    while (args.next()) |arg| {
        var split = std.mem.splitSequence(u8, arg, ":");
        const key_name = split.next() orelse return usage(program_name);
        const key_base64 = split.next() orelse return usage(program_name);
        if (split.next() != null) {
            return usage(program_name);
        }

        const decoded_len = try std.base64.standard.Decoder.calcSizeForSlice(key_base64);

        const key_data = try allocator.alloc(u8, decoded_len);
        errdefer allocator.free(key_data);

        try std.base64.standard.Decoder.decode(key_data, key_base64);

        try keys.put(key_name, key_data);
    }

    defer {
        var iter = keys.iterator();
        while (iter.next()) |key| {
            allocator.free(key.value_ptr.*);
        }
    }

    var data_file = try std.fs.cwd().openFile(data_filepath, .{});
    defer data_file.close();

    const data_contents = try data_file.readToEndAlloc(allocator, 4096);
    defer allocator.free(data_contents);

    var signature_file = try std.fs.cwd().openFile(signature_filepath, .{});
    defer signature_file.close();

    const signature_contents = try signature_file.readToEndAlloc(allocator, 4096);
    defer allocator.free(signature_contents);

    var split = std.mem.splitSequence(u8, signature_contents, ":");
    const signature_key_name = split.next() orelse return usage(program_name);
    const signature_contents_base64 = split.next() orelse return usage(program_name);
    if (split.next() != null) {
        return usage(program_name);
    }

    const signature_decoded_len = try std.base64.standard.Decoder.calcSizeForSlice(signature_contents_base64);
    const signature_decoded = try allocator.alloc(u8, signature_decoded_len);
    defer allocator.free(signature_decoded);

    try std.base64.standard.Decoder.decode(signature_decoded, signature_contents_base64);

    const public_key = keys.get(signature_key_name) orelse {
        std.log.err("Key with name '{s}' not found", .{signature_key_name});
        return error.MissingVerifyKey;
    };

    if (C.crypto_sign_verify_detached(
        signature_decoded.ptr,
        data_contents.ptr,
        data_contents.len,
        public_key.ptr,
    ) != 0) {
        std.process.exit(1);
    }
}

// zig run overlays/pkgs/nix-key/nix-key.zig -lc -lsodium -L ./result/lib -I ./result-dev/include -- sign /tmp/key /tmp/key
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer {
        _ = gpa.deinit();
    }

    var args = try std.process.argsWithAllocator(gpa.allocator());
    defer args.deinit();

    const program_name = args.next() orelse unreachable;

    const action = args.next() orelse return usage(program_name);

    if (std.mem.eql(u8, action, "sign")) {
        return sign(gpa.allocator(), program_name, &args);
    } else if (std.mem.eql(u8, action, "verify")) {
        return verify(gpa.allocator(), program_name, &args);
    } else {
        return usage(program_name);
    }
}
