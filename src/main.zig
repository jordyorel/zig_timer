const std = @import("std");
const parser = @import("parse_input.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(gpa_allocator);
    defer std.process.argsFree(gpa_allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <duration_string>\n", .{args[0]});
        std.debug.print("Example: {s} 5m3s\n", .{args[0]});
        return error.NotEnoughArguments;
    }

    var total_second: u64 = 0;
    for (args[1..]) |arg| {
        const duration = try parser.Duration.parseInput(arg);
        total_second += duration.total_seconds;
    }

    std.debug.print("Timer launched for {d} seconds.\n", .{total_second});

    const io = std.testing.io;
    const stdout = std.fs.File.stdout();

    var time_buf: [9]u8 = undefined;

    while (total_second > 0) {
        const formatted_time = try parser.Duration.formatTime(&time_buf, total_second);

        try stdout.writeAll("\rRemaining time : ");
        try stdout.writeAll(formatted_time);

        try std.Io.Clock.Duration.sleep(.{ .clock = .awake, .raw = std.Io.Duration.fromSeconds(1) }, io);

        total_second -= 1;
    }

    try stdout.writeAll("\rElapsed time : 00:00:00");
    try stdout.writeAll("\n--- TIME ELAPSED ! ---\n");
}
