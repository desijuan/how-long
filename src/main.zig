const std = @import("std");

pub fn main() u8 {
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

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
                stderr.print("Expecting 4 digits, got {d}: {s}\n", .{ len, arg }) catch {};
                return 1;
            },
        };

        is_last = !is_last;

        const hours_str = str[0..2];
        const mins_str = str[2..4];

        const hours: u32 = std.fmt.parseInt(u32, hours_str, 10) catch {
            stderr.print("Unable to parse hours: {s}\n", .{arg}) catch {};
            return 1;
        };

        const mins: u32 = std.fmt.parseInt(u32, mins_str, 10) catch {
            stderr.print("Unable to parse minutes: {s}\n", .{arg}) catch {};
            return 1;
        };

        if (hours > 23) {
            stderr.print("Hours number {d} is too big\n", .{hours}) catch {};
            return 1;
        }

        if (mins > 59) {
            stderr.print("Minutes number {d} is too big\n", .{mins}) catch {};
            return 1;
        }

        const mins1: u32 = 60 * hours + mins;

        if (mins1 < mins0) {
            const time0 = Time.fromMins(mins0);
            const time1 = Time.fromMins(mins1);
            stderr.print("Wrong Delta: {} -> {}\n", .{ time0, time1 }) catch {};
            return 1;
        }

        if (is_last) mins_sum += mins1 - mins0;

        mins0 = mins1;
    }

    if (!is_last) stdout.writeAll("\nWARNING: Missing last entry\n\n") catch
        return 1;

    const total_time = Time.fromMins(mins_sum);

    stdout.print("{}\n", .{total_time}) catch
        return 1;

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
