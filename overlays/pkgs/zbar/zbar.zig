const std = @import("std");
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
            .it_value = .{ .sec = 1, .nsec = 0 },
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

const Module = union(enum) {
    date_time: DateTime,

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

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const arena_allocator = arena.allocator();

    const epollfd = try posix.epoll_create1(0);
    defer posix.close(epollfd);

    var modules = [_]Module{.{
        .date_time = try DateTime.init(epollfd),
    }};

    defer {
        for (modules[0..]) |*module| {
            module.deinit();
        }
    }

    while (true) {
        defer _ = arena.reset(.retain_capacity);

        var events = [_]posix.system.epoll_event{undefined} ** modules.len;

        const n_events = posix.epoll_wait(epollfd, &events, -1);

        var index: usize = 0;
        while (index < n_events) : (index += 1) {
            const event = events[index];

            for (modules[0..]) |*module| {
                if (event.data.fd == module.fd()) {
                    if (module.render(arena_allocator)) |maybe_content| {
                        if (maybe_content) |content| {
                            try std.io.getStdOut().writer().print("{s}\n", .{content});
                        }
                    } else |err| {
                        std.log.err("module '{s}' failure: {}", .{ "TODO_module_name", err });
                    }
                } else {
                    std.log.warn("unhandled event on fd {}", .{event.data.fd});
                }
            }
        }
    }
}
