const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var args = std.process.args();
    _ = args.next().?;

    var mins_sum: u32 = 0;

    var is_last: bool = false;
    var mins0: u32 = 0;

    while (args.next()) |arg| {
        if (arg.len != 4) return error.MalformedTime;

        const hours_str = arg[0..2];
        const mins_str = arg[2..4];

        const hours: u32 = try std.fmt.parseInt(u32, hours_str, 10);
        const mins: u32 = try std.fmt.parseInt(u32, mins_str, 10);

        if (hours > 23) return error.InvalidHours;
        if (mins > 59) return error.InvalidMins;

        const mins1: u32 = 60 * hours + mins;

        if (mins1 < mins0) return error.WrongDelta;

        if (is_last) mins_sum += mins1 - mins0;

        mins0 = mins1;
        is_last = !is_last;
    }

    const total_hours: u32 = mins_sum / 60;
    const total_mins: u32 = mins_sum % 60;

    try stdout.print("{d:0>2}:{d:0>2}\n", .{ total_hours, total_mins });
}
