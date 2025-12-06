const std = @import("std");

const ParseError = error{
    InvalidFormat,
    UnitMissing,
    Overflow,
    ZeorDuration,
};

const Duration = struct {
    total_seconds: u64 = 0,

    fn parseInput(input: []const u8) !Duration {
        var total: u64 = 0;
        var current: u64 = 0;
        var i: usize = 0;

        while (i < input.len) {
            const c = input[i];
            i += 1;

            switch (c) {
                '0'...'9' => {
                    const mult_res = @mulWithOverflow(current, 10);
                    if (mult_res[1] != 0) {
                        return ParseError.Overflow;
                    }
                    current = mult_res[0] + (c - '0');
                },
                'h', 'm', 's' => {
                    if (current == 0) return ParseError.UnitMissing;
                    const multiplier: u64 = switch (c) {
                        'h' => 3600,
                        'm' => 60,
                        's' => 1,
                        else => unreachable,
                    };
                    const unit_value = @mulWithOverflow(current, multiplier);
                    if (unit_value[1] != 0) return ParseError.Overflow;
                    const total_res = @addWithOverflow(total, unit_value[0]);
                    if (total_res[1] != 0) return ParseError.Overflow;
                    total = total_res[0];
                    current = 0;
                },
                ' ' => {},
                else => return error.InvalidFormat,
            }
        }

        if (current != 0) {
            total += current;
        }
        if (total == 0) return error.ZeorDuration;
        return Duration{ .total_seconds = total };
    }

    fn formatTime(total_seconds: u64) [9]u8 {
        const H = total_seconds / 3600;
        const M = (total_seconds % 3600) / 60;
        const S = total_seconds % 60;

        var buffer: [9]u8 = undefined;

        _ = std.fmt.bufPrint(&buffer, "{:0>2}:{:0>2}:{:0>2}\x00", .{ H, M, S }) catch |err| {
            std.debug.print("Formating Error: {}\n", .{err});
            return [_]u8{ '0', '0', ':', '0', '0', ':', '0', '0', 0 };
        };
        return buffer;
    }
};

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
        const duration = try Duration.parseInput(arg);
        total_second = duration.total_seconds;
    }

    std.debug.print("Timer launched for {d} seconds.\n", .{total_second});

    const stdout = std.fs.File.stdout();
    const io = std.testing.io;

    while (total_second > 0) {
        const formatted_time = Duration.formatTime(total_second);

        try stdout.writeAll("\rRemaining time : ");
        try stdout.writeAll(formatted_time[0..8]);

        try std.Io.Clock.Duration.sleep(.{ .clock = .awake, .raw = std.Io.Duration.fromSeconds(1) }, io);

        total_second -= 1;
    }

    try stdout.writeAll("\rElapsed time : 00:00:00");
    try stdout.writeAll("\n--- TIME ELAPSED ! ---\n");
}
