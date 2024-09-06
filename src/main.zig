const std = @import("std");

pub fn main() void {
    const stdout = std.io.getStdOut().writer();

    var args = std.process.args();
    _ = args.next().?;

    var buffer: [4]u8 = undefined;

    var mins_sum: u32 = 0;

    var is_last: bool = false;
    var mins0: u32 = 0;

    while (args.next()) |arg| {
        const str: []const u8 = switch (arg.len) {
            3, 4 => std.fmt.bufPrint(&buffer, "{s:0>4}", .{arg}) catch
                @panic("Unable to parse args"),

            else => @panic("Malformed Time"),
        };

        const hours_str = str[0..2];
        const mins_str = str[2..4];

        const hours: u32 = std.fmt.parseInt(u32, hours_str, 10) catch
            @panic("Unable to parse the hours string");

        const mins: u32 = std.fmt.parseInt(u32, mins_str, 10) catch
            @panic("Unable to parse the minutes string");

        if (hours > 23) @panic("Invalud Hours");
        if (mins > 59) @panic("Invalid Minutes");

        const mins1: u32 = 60 * hours + mins;

        if (mins1 < mins0) @panic("Wrong Delta");

        if (is_last) mins_sum += mins1 - mins0;

        mins0 = mins1;
        is_last = !is_last;
    }

    const total_hours: u32 = mins_sum / 60;
    const total_mins: u32 = mins_sum % 60;

    stdout.print("{d:0>2}:{d:0>2}\n", .{ total_hours, total_mins }) catch
        @panic("Unable to print to stdout");
}
