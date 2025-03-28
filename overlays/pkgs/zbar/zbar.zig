const std = @import("std");
const posix = std.posix;
const linux = std.os.linux;

const C = @cImport({
    @cInclude("time.h");
});

pub fn main() !void {
    const epoll_fd = try posix.epoll_create1(0);
    defer posix.close(epoll_fd);

    const timer_fd = try posix.timerfd_create(.MONOTONIC, .{});

    try posix.timerfd_settime(timer_fd, .{}, &.{
        .it_value = .{ .sec = 1, .nsec = 0 },
        .it_interval = .{ .sec = 1, .nsec = 0 },
    }, null);

    var timer_event = linux.epoll_event{
        .data = .{ .fd = timer_fd },
        .events = linux.EPOLL.IN,
    };

    try posix.epoll_ctl(epoll_fd, linux.EPOLL.CTL_ADD, timer_fd, &timer_event);

    while (true) {
        var events = [_]posix.system.epoll_event{undefined} ** 10;

        const n_events = posix.epoll_wait(epoll_fd, &events, -1);

        var index: usize = 0;
        while (index < n_events) : (index += 1) {
            const event = events[index];

            if (event.data.fd == timer_fd) {
                var exp: u64 = undefined;
                const n_read = try posix.read(timer_fd, std.mem.asBytes(&exp));
                std.debug.assert(n_read == @sizeOf(@TypeOf(exp)));

                var now: C.time_t = undefined;
                _ = C.time(&now);
                const timeinfo = C.localtime(&now);
                const s = C.asctime(timeinfo);

                try std.io.getStdOut().writer().print("{s}", .{s});
            } else {
                std.log.warn("unhandled event on fd {}", .{event.data.fd});
            }
        }
    }
}
