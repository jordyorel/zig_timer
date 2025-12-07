const std = @import("std");
const builtin = @import("builtin");

pub fn notifyCompletion(allocator: std.mem.Allocator, total_seconds: u64) void {
    var message_buf: [64]u8 = undefined;
    const message = std.fmt.bufPrint(&message_buf, "Timer finished after {d}s", .{total_seconds}) catch return;
    // _= message;

    // _= total_seconds;

    switch (builtin.os.tag) {
        .macos, .ios, .watchos, .tvos, .visionos => {
            // Emit a terminal bell as a fallback.
            std.fs.File.stdout().writeAll("\x07") catch {};
            var notify_child = std.process.Child.init(&[_][]const u8{ 
                "osasscript", 
                "-e", 
                "display notification \"Timer finished after\"with title \"Zig Timer\" sound name \"Ping\"" 
            }, allocator);
            notify_child.stdin_behavior = .Ignore;
            notify_child.stdout_behavior = .Ignore;
            notify_child.stderr_behavior = .Ignore;
            _ = notify_child.spawnAndWait() catch {};
        },
        .linux, .freebsd, .netbsd, .openbsd, .dragonfly => {
            var child = std.process.Child.init(&[_][]const u8{
                "notify-send",
                "zig-timer",
                message,
            }, allocator);
            child.stdin_behavior = .Ignore;
            child.stdout_behavior = .Ignore;
            child.stderr_behavior = .Ignore;
            _ = child.spawnAndWait() catch {};
        },
        else => {
            std.fs.File.writeAll("\x07") catch {};
        },
    }
}
