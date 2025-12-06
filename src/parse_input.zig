const std = @import("std");

const ParseError = error{
    InvalidFormat,
    UnitMissing,
    Overflow,
    ZeroDuration,
};

pub const Duration = struct {
    total_seconds: u64 = 0,

    pub fn parseInput(input: []const u8) !Duration {
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
                    const add_res = @addWithOverflow(mult_res[0], c - '0');
                    if (add_res[1] != 0) return ParseError.Overflow;
                    current = add_res[0];
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
        if (total == 0) return error.ZeroDuration;
        return Duration{ .total_seconds = total };
    }

    pub fn formatTime(buf: *[9]u8, total_seconds: u64) ![]const u8 {
        const H = total_seconds / 3600;
        const M = (total_seconds % 3600) / 60;
        const S = total_seconds % 60;
        _ = try std.fmt.bufPrint(buf, "{:0>2}:{:0>2}:{:0>2}", .{ H, M, S });
        return buf.*[0..8];
    }
};

test "parseInput handles mixed duration units" {
    const cases = [_]struct {
        input: []const u8,
        expected: u64,
    }{
        .{ .input = "5s", .expected = 5 },
        .{ .input = "2m", .expected = 120 },
        .{ .input = "1h30m15s", .expected = 3600 + 1800 + 15 },
        .{ .input = " 10m 5s ", .expected = 605 },
    };

    for (cases) |case| {
        const duration = try Duration.parseInput(case.input);
        try std.testing.expectEqual(case.expected, duration.total_seconds);
    }
}

test "parseInput reports invalid inputs" {
    try std.testing.expectError(ParseError.InvalidFormat, Duration.parseInput("bad"));
    try std.testing.expectError(ParseError.UnitMissing, Duration.parseInput("ms"));
    try std.testing.expectError(ParseError.ZeroDuration, Duration.parseInput("0"));
}

test "parseInput detects overflow" {
    try std.testing.expectError(ParseError.Overflow, Duration.parseInput("18446744073709551616s"));
}

test "formatTime returns zero padded clock string" {
    var buf: [9]u8 = undefined;
    const formatted = try Duration.formatTime(&buf, 3661);
    try std.testing.expectEqualStrings("01:01:01", formatted);
}
