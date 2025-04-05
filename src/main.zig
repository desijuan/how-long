const std = @import("std");

pub const std_options = std.Options{
    .log_level = .info,
};

pub fn main() u8 {
    const stdout = std.io.getStdOut().writer();

    var buffer: [4]u8 = undefined;

    var mins_sum: u32 = 0;
    var mins0: u32 = 0;
    var is_last: bool = true;

    var args = std.process.args();
    _ = args.next().?;

    while (args.next()) |arg| {
        const str: []const u8 = switch (arg.len) {
            3, 4 => std.fmt.bufPrint(&buffer, "{s:0>4}", .{arg}) catch unreachable,

            else => |len| {
                std.log.err("Expecting 4 digits, got {d}: {s}", .{ len, arg });
                return 1;
            },
        };

        is_last = !is_last;

        const hours_str = str[0..2];
        const mins_str = str[2..4];

        const hours: u32 = std.fmt.parseInt(u32, hours_str, 10) catch {
            std.log.err("Unable to parse hours: {s}", .{arg});
            return 1;
        };

        const mins: u32 = std.fmt.parseInt(u32, mins_str, 10) catch {
            std.log.err("Unable to parse minutes: {s}", .{arg});
            return 1;
        };

        if (hours > 23) {
            std.log.err("Hours number {d} is too big", .{hours});
            return 1;
        }

        if (mins > 59) {
            std.log.err("Minutes number {d} is too big", .{mins});
            return 1;
        }

        const mins1: u32 = 60 * hours + mins;

        if (mins1 < mins0) {
            std.log.err("Wrong Delta: {} -> {}", .{ Time.fromMins(mins0), Time.fromMins(mins1) });
            return 1;
        }

        if (is_last) mins_sum += mins1 - mins0;

        mins0 = mins1;
    }

    if (!is_last) std.log.warn("Missing last entry. Ignoring value {}.", .{Time.fromMins(mins0)});

    const total_time = Time.fromMins(mins_sum);

    stdout.print("{}\n", .{total_time}) catch return 1;

    return 0;
}

const Time = struct {
    hours: u32,
    mins: u32,

    fn fromMins(total_mins: u32) Time {
        return Time{
            .hours = total_mins / 60,
            .mins = total_mins % 60,
        };
    }

    pub fn format(
        self: Time,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "{d:0>2}:{d:0>2}", .{ self.hours, self.mins });
    }
};
