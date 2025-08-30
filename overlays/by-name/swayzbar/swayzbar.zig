const std = @import("std");
const json = std.json;
const posix = std.posix;
const system = std.posix.system;
const EPOLL = std.os.linux.EPOLL;

const C = @cImport({
    @cInclude("time.h");
});

var in_buffer = [_]u8{0} ** 4096;
var out_buffer = [_]u8{0} ** 4096;

const Clock = struct {
    timerfd: posix.fd_t,

    pub fn init() !@This() {
        const timerfd = try posix.timerfd_create(.MONOTONIC, .{});

        try posix.timerfd_settime(timerfd, .{}, &.{
            // set to small non-zero value so it runs for the first time _almost_ immediately
            .it_value = .{ .sec = 0, .nsec = 1 },
            .it_interval = .{ .sec = 1, .nsec = 0 },
        }, null);

        return .{ .timerfd = timerfd };
    }

    pub fn fd(self: *@This()) posix.fd_t {
        return self.timerfd;
    }

    pub fn render(self: *@This(), allocator: std.mem.Allocator) !?[]const u8 {
        var exp: u64 = undefined;
        const n_read = try posix.read(self.timerfd, std.mem.asBytes(&exp));
        std.debug.assert(n_read == @sizeOf(@TypeOf(exp)));

        const now = C.time(null);
        const localnow = C.localtime(&now);

        const gmt_offset = @divExact(localnow.*.tm_gmtoff, 3600) * 100 + @divExact(@mod(localnow.*.tm_gmtoff, 3600), 60);
        const gmt_offset_sign = if (gmt_offset >= 0) "+" else "-";

        return try std.fmt.allocPrint(allocator, "{:0>4}-{:0>2}-{:0>2} {:0>2}:{:0>2}:{:0>2} {s}{:0>4}", .{
            @as(u32, @intCast(1900 + localnow.*.tm_year)), // number of years since 1900
            @as(u8, @intCast(1 + localnow.*.tm_mon)), // zero-indexed
            @as(u8, @intCast(localnow.*.tm_mday)),
            @as(u8, @intCast(localnow.*.tm_hour)),
            @as(u8, @intCast(localnow.*.tm_min)),
            @as(u8, @intCast(localnow.*.tm_sec)),
            gmt_offset_sign,
            @abs(gmt_offset),
        });
    }

    pub fn deinit(self: *@This()) void {
        posix.close(self.timerfd);
    }
};

const Battery = struct {
    uevents: [10]?std.fs.File,
    timerfd: posix.fd_t,

    pub fn init() !@This() {
        const timerfd = try posix.timerfd_create(.MONOTONIC, .{});

        try posix.timerfd_settime(timerfd, .{}, &.{
            // set to small non-zero value so it runs for the first time _almost_ immediately
            .it_value = .{ .sec = 0, .nsec = 1 },
            .it_interval = .{ .sec = 10, .nsec = 0 },
        }, null);

        var power_supply_class_dir = try std.fs.cwd().openDir(
            "/sys/class/power_supply",
            .{ .iterate = true },
        );
        defer power_supply_class_dir.close();

        var uevents_index: usize = 0;
        var uevent_contents: [4096]u8 = undefined;
        var uevents = [_]?std.fs.File{null} ** 10;
        var power_supply_class_dir_iterator = power_supply_class_dir.iterate();
        while (try power_supply_class_dir_iterator.next()) |power_supply_entry| {
            var power_supply_dir = try power_supply_class_dir.openDir(power_supply_entry.name, .{});
            defer power_supply_dir.close();

            const uevent = try power_supply_dir.openFile("uevent", .{});
            errdefer uevent.close();

            const n = try uevent.readAll(&uevent_contents);
            var lines = std.mem.splitSequence(u8, uevent_contents[0..n], "\n");
            var is_battery = false;
            while (lines.next()) |line| {
                if (std.mem.eql(u8, line, "POWER_SUPPLY_TYPE=Battery")) {
                    uevents[uevents_index] = uevent;
                    uevents_index += 1;
                    is_battery = true;
                    break;
                }
            }

            if (!is_battery) {
                uevent.close();
            }
        }

        return .{ .timerfd = timerfd, .uevents = uevents };
    }

    pub fn fd(self: *@This()) posix.fd_t {
        return self.timerfd;
    }

    pub fn render(self: *@This(), allocator: std.mem.Allocator) !?[]const u8 {
        var exp: u64 = undefined;
        const n_read = try posix.read(self.timerfd, std.mem.asBytes(&exp));
        std.debug.assert(n_read == @sizeOf(@TypeOf(exp)));

        var rendered = std.io.Writer.Allocating.init(allocator);
        errdefer rendered.deinit();
        var writer = &rendered.writer;

        var uevent_contents: [4096]u8 = undefined;
        for (self.uevents) |uevent| {
            if (uevent) |file| {
                try file.seekTo(0);
                const n = try file.readAll(&uevent_contents);
                var lines = std.mem.splitSequence(u8, uevent_contents[0..n], "\n");

                var bat_name: ?[]const u8 = null;
                var full: ?usize = null;
                var now: ?usize = null;

                while (lines.next()) |line| {
                    var key_val = std.mem.splitSequence(u8, line, "=");
                    const key = key_val.next() orelse continue;
                    const val = key_val.next() orelse continue;

                    if (std.mem.eql(u8, key, "POWER_SUPPLY_NAME")) {
                        bat_name = val;
                    } else if (std.mem.eql(u8, key, "POWER_SUPPLY_CHARGE_FULL")) {
                        full = try std.fmt.parseInt(usize, val, 10);
                    } else if (std.mem.eql(u8, key, "POWER_SUPPLY_ENERGY_FULL")) {
                        full = try std.fmt.parseInt(usize, val, 10);
                    } else if (std.mem.eql(u8, key, "POWER_SUPPLY_CHARGE_NOW")) {
                        now = try std.fmt.parseInt(usize, val, 10);
                    } else if (std.mem.eql(u8, key, "POWER_SUPPLY_ENERGY_NOW")) {
                        now = try std.fmt.parseInt(usize, val, 10);
                    }
                }

                try writer.print("{s}: {d}%", .{
                    bat_name orelse continue,
                    100 * (now orelse continue) / (full orelse continue),
                });
            }
        }

        const content = try rendered.toOwnedSlice();
        if (std.mem.eql(u8, content, "")) {
            return null;
        } else {
            return content;
        }
    }

    pub fn deinit(self: *@This()) void {
        posix.close(self.timerfd);

        for (self.uevents) |uevent| {
            if (uevent) |file| {
                file.close();
            }
        }
    }
};

const Module = union(enum) {
    date_time: Clock,
    battery: Battery,

    pub fn name(self: *@This()) []const u8 {
        return switch (self.*) {
            inline else => |*module| @typeName(@TypeOf(module)),
        };
    }

    pub fn fd(self: *@This()) posix.fd_t {
        return switch (self.*) {
            inline else => |*module| module.fd(),
        };
    }

    pub fn render(self: *@This(), allocator: std.mem.Allocator) !?[]const u8 {
        return switch (self.*) {
            inline else => |*module| module.render(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        return switch (self.*) {
            inline else => |*module| module.deinit(),
        };
    }
};

const Header = struct {
    /// The protocol version to use. Currently, this must be 1
    version: u8 = 1,

    /// Whether to receive click event information to standard input
    click_events: ?bool = null,

    /// The signal that swaybar should send to continue processing
    cont_signal: ?u32 = null,

    /// The signal that swaybar should send to stop processing
    stop_signal: ?u32 = null,
};

const Block = struct {
    /// The text that will be displayed. If missing, the block will be skipped.
    full_text: []const u8,

    /// If given and the text needs to be shortened due to space, this will be displayed instead of full_text
    short_text: ?[]const u8 = null,

    /// The text color to use in #RRGGBBAA or #RRGGBB notation
    color: ?[]const u8 = null,

    /// The background color for the block in #RRGGBBAA or #RRGGBB notation
    background: ?[]const u8 = null,

    /// The border color for the block in #RRGGBBAA or #RRGGBB notation
    border: ?[]const u8 = null,

    /// The height in pixels of the top border. The default is 1
    border_top: ?u32 = null,

    /// The height in pixels of the bottom border. The default is 1
    border_bottom: ?u32 = null,

    /// The width in pixels of the left border. The default is 1
    border_left: ?u32 = null,

    /// The width in pixels of the right border. The default is 1
    border_right: ?u32 = null,

    /// The minimum width to use for the block. This can either be given in pixels or a string can be given to allow for it to be calculated based on the width of the string.
    min_width: ?u32 = null,

    /// If the text does not span the full width of the block, this specifies how the text should be aligned inside of the block. This can be left (default), right, or center.
    @"align": ?[]const u8 = null,

    /// A name for the block. This is only used to identify the block for click events. If set, each block should have a unique name and instance pair.
    name: ?[]const u8 = null,

    /// The instance of the name for the block. This is only used to identify the block for click events. If set, each block should have a unique name and instance pair.
    instance: ?[]const u8 = null,

    /// Whether the block should be displayed as urgent. Currently swaybar utilizes the colors set in the sway config for urgent workspace buttons. See sway-bar(5) for more information on bar color configuration.
    urgent: ?bool = null,

    /// Whether the bar separator should be drawn after the block. See sway-bar(5) for more information on how to set the separator text.
    separator: ?bool = null,

    /// The amount of pixels to leave blank after the block. The separator text will be displayed centered in this gap. The default is 9 pixels.
    separator_block_width: ?u32 = null,

    /// The type of markup to use when parsing the text for the block. This can either be pango or none (default).
    markup: ?[]const u8 = null,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer {
        _ = gpa.deinit();
    }

    const allocator = gpa.allocator();

    const epollfd = try posix.epoll_create1(0);
    defer posix.close(epollfd);

    var stdin_event = system.epoll_event{
        .data = .{ .ptr = 0 },
        .events = EPOLL.IN,
    };
    try posix.epoll_ctl(epollfd, EPOLL.CTL_ADD, posix.STDIN_FILENO, &stdin_event);

    var modules = [_]Module{
        .{ .battery = try Battery.init() },
        .{ .date_time = try Clock.init() },
    };

    // Register each module's input file descriptor on the epoll file
    // descriptor.
    for (&modules) |*module| {
        var module_event = system.epoll_event{
            .data = .{ .ptr = @intFromPtr(module) },
            .events = EPOLL.IN,
        };

        try posix.epoll_ctl(epollfd, EPOLL.CTL_ADD, module.fd(), &module_event);
    }

    var blocks = [_]?Block{null} ** modules.len;

    defer {
        for (modules[0..]) |*module| {
            module.deinit();
        }
    }

    var stdin_file = std.fs.File.stdin().reader(&in_buffer);
    var stdin = &stdin_file.interface;

    var stdout_file = std.fs.File.stdout().writer(&out_buffer);
    var stdout = &stdout_file.interface;

    try json.Stringify.value(Header{}, .{ .emit_null_optional_fields = false }, stdout);
    try stdout.writeByte('\n');
    try stdout.flush();

    var json_stream = json.Stringify{ .writer = stdout, .options = .{ .emit_null_optional_fields = false } };

    try json_stream.beginArray();

    while (true) {
        var events = [_]posix.system.epoll_event{undefined} ** modules.len;

        const n_events = posix.epoll_wait(epollfd, &events, -1);

        var index: usize = 0;
        while (index < n_events) : (index += 1) {
            const event = events[index];

            // Sentinel value meaning we got data on stdin
            if (event.data.ptr == 0) {
                // We don't yet do anything with stdin data, just consume it.
                std.log.debug("got click event", .{});
                _ = try stdin.discardDelimiterInclusive('\n');
                continue;
            } else {
                const module: *Module = @ptrFromInt(event.data.ptr);

                for (&modules, 0..) |*m, i| {
                    if (m != module) {
                        continue;
                    }

                    if (module.render(allocator)) |maybe_content| {
                        if (maybe_content) |content| {
                            if (blocks[i]) |current| {
                                allocator.free(current.full_text);
                            }

                            blocks[i] = Block{ .full_text = content };
                        }
                    } else |err| {
                        std.log.err(
                            "module '{s}' failure: {}",
                            .{ module.name(), err },
                        );
                    }
                }
            }
        }

        try json_stream.beginArray();

        for (blocks) |block| {
            if (block) |b| {
                try json_stream.write(b);
            }
        }

        try json_stream.endArray();
        try json_stream.writer.flush();
    }
}
