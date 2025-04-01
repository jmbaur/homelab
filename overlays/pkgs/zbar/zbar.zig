const std = @import("std");
const json = std.json;
const posix = std.posix;
const linux = std.os.linux;

const C = @cImport({
    @cInclude("time.h");
});

const DateTime = struct {
    timerfd: posix.fd_t,

    pub fn init(epollfd: posix.fd_t) !@This() {
        const timerfd = try posix.timerfd_create(.MONOTONIC, .{});

        try posix.timerfd_settime(timerfd, .{}, &.{
            // set to small non-zero value so it runs for the first time _almost_ immediately
            .it_value = .{ .sec = 0, .nsec = 1 },
            .it_interval = .{ .sec = 1, .nsec = 0 },
        }, null);

        var timer_event = linux.epoll_event{
            .data = .{ .fd = timerfd },
            .events = linux.EPOLL.IN,
        };

        try posix.epoll_ctl(epollfd, linux.EPOLL.CTL_ADD, timerfd, &timer_event);

        return .{ .timerfd = timerfd };
    }

    pub fn fd(self: *@This()) posix.fd_t {
        return self.timerfd;
    }

    pub fn render(self: *@This(), allocator: std.mem.Allocator) !?[]const u8 {
        var exp: u64 = undefined;
        const n_read = try posix.read(self.timerfd, std.mem.asBytes(&exp));
        std.debug.assert(n_read == @sizeOf(@TypeOf(exp)));

        var now: C.time_t = undefined;
        _ = C.time(&now);
        const timeinfo = C.localtime(&now);
        const timeinfo_str = std.mem.span(C.asctime(timeinfo));

        return try allocator.dupe(u8, std.mem.trim(u8, timeinfo_str, &std.ascii.whitespace));
    }

    pub fn deinit(self: *@This()) void {
        posix.close(self.timerfd);
    }
};

const Battery = struct {
    uevents: [10]?std.fs.File,
    timerfd: posix.fd_t,

    pub fn init(epollfd: posix.fd_t) !@This() {
        const timerfd = try posix.timerfd_create(.MONOTONIC, .{});

        try posix.timerfd_settime(timerfd, .{}, &.{
            // set to small non-zero value so it runs for the first time _almost_ immediately
            .it_value = .{ .sec = 0, .nsec = 1 },
            .it_interval = .{ .sec = 10, .nsec = 0 },
        }, null);

        var timer_event = linux.epoll_event{
            .data = .{ .fd = timerfd },
            .events = linux.EPOLL.IN,
        };

        try posix.epoll_ctl(epollfd, linux.EPOLL.CTL_ADD, timerfd, &timer_event);

        var power_supply_class_dir = try std.fs.cwd().openDir("/sys/class/power_supply", .{ .iterate = true });
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

        var rendered = std.ArrayList(u8).init(allocator);

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

                try rendered.writer().print("{s}: {d}%", .{
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
    date_time: DateTime,
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
    version: u8 = 1,
};

const Body = struct {
    full_text: []const u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer {
        _ = gpa.deinit();
    }

    const epollfd = try posix.epoll_create1(0);
    defer posix.close(epollfd);

    var modules = [_]Module{
        .{ .battery = try Battery.init(epollfd) },
        .{ .date_time = try DateTime.init(epollfd) },
    };

    var body_list = [_]?Body{null} ** modules.len;

    defer {
        for (modules[0..]) |*module| {
            module.deinit();
        }
    }

    const stdout = std.io.getStdOut().writer();
    try json.stringify(Header{}, .{}, stdout);
    try stdout.writeAll("\n[\n");

    while (true) {
        var events = [_]posix.system.epoll_event{undefined} ** modules.len;

        const n_events = posix.epoll_wait(epollfd, &events, -1);

        var index: usize = 0;
        while (index < n_events) : (index += 1) {
            const event = events[index];

            var found = false;
            for (modules[0..], 0..) |*module, i| {
                if (event.data.fd == module.fd()) {
                    found = true;

                    if (module.render(gpa.allocator())) |maybe_content| {
                        if (maybe_content) |content| {
                            if (body_list[i]) |current| {
                                gpa.allocator().free(current.full_text);
                            }

                            body_list[i] = Body{ .full_text = content };
                        }
                    } else |err| {
                        std.log.err("module '{s}' failure: {}", .{ module.name(), err });
                    }
                }
            }

            if (!found) {
                std.log.warn("unhandled event on fd {}", .{event.data.fd});
            }
        }

        try json.stringify(
            body_list,
            .{ .emit_null_optional_fields = false },
            stdout,
        );
        try stdout.writeAll(",\n");
    }
}
