const std = @import("std");
const builtin = @import("builtin");

const parser = @import("parse_input.zig");
const notification = @import("notification.zig");

const AppError = error{
    NoDurationProvided,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(gpa_allocator);
    defer std.process.argsFree(gpa_allocator, args);

    var notify = false;
    var total_seconds: u64 = 0;
    var has_argument = false;
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--notify")) {
            notify = true;
            continue;
        }

        const duration = try parser.Duration.parseInput(arg);
        total_seconds += duration.total_seconds;
        has_argument = true;
    }

    if (!has_argument or total_seconds == 0) {
        std.debug.print("Usage: {s} <duration_string>\n", .{args[0]});
        std.debug.print("Example: {s} 1h30m\n", .{args[0]});
        return error.InvalidArgs;
    }

    std.debug.print("Timer launched for {d} seconds.\n", .{total_seconds});

    const io = std.testing.io;
    const stdout = std.fs.File.stdout();

    var time_buf: [9]u8 = undefined; // "HH:MM:SS"
    const timer_length = total_seconds;

    var remaining = total_seconds;
    while (remaining > 0) {
        const formatted_time = try parser.Duration.formatTime(&time_buf, remaining);
        try stdout.writeAll("\rRemaining time : ");
        try stdout.writeAll(formatted_time);
        try stdout.writeAll("   ");
        try std.Io.Clock.Duration.sleep(.{ .clock = .awake, .raw = std.Io.Duration.fromSeconds(1) }, io);
        remaining -= 1;
    }

    try stdout.writeAll("\rElapsed time : 00:00:00                      \n");
    try stdout.writeAll("\n--- TIME ELAPSED ! ---\n");

    if (notify) {
        notification.notifyCompletion(gpa_allocator, timer_length);
    }
}
