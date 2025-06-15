const std = @import("std");
const hl = @import("hl.zig");
const c = @cImport(@cInclude("time.h"));

pub const std_options = std.Options{
    .log_level = .info,
};

const Gpa = @import("allocator.zig").Gpa;

pub fn main() error{OutOfMemory}!u8 {
    defer if (comptime @hasDecl(Gpa, "deinit")) Gpa.deinit();
    const gpa = Gpa.allocator();

    var list = try std.ArrayList(hl.Interval).initCapacity(gpa, 32);
    defer list.deinit();

    // zig fmt: off
    var bw = std.io.BufferedWriter(256, std.fs.File.Writer){
        .unbuffered_writer = std.io.getStdOut().writer(),
    }; defer bw.flush() catch {};
    // zig fmt: on

    const stdout = bw.writer();

    var buf1: [4]u8 = undefined;
    var is_last: bool = false;
    var mins0: hl.Time = .{ .tmins = 0 };

    var args: std.process.ArgIterator = try std.process.argsWithAllocator(gpa);
    _ = args.next().?;

    while (args.next()) |arg| {
        const str: []const u8 = switch (arg.len) {
            3, 4 => std.fmt.bufPrint(&buf1, "{s:0>4}", .{arg}) catch unreachable,

            else => |len| {
                std.log.err("Expecting 4 digits, got {d}: {s}", .{ len, arg });
                return 1;
            },
        };

        const hours_str: *const [2]u8 = str[0..2];
        const mins_str: *const [2]u8 = str[2..4];

        const hours: u32 = std.fmt.parseInt(u32, hours_str, 10) catch {
            std.log.err("Unable to parse hours: {s}", .{arg});
            return 1;
        };

        if (hours > 23) {
            std.log.err("Hours number {d} is too big", .{hours});
            return 1;
        }

        const mins: u32 = std.fmt.parseInt(u32, mins_str, 10) catch {
            std.log.err("Unable to parse minutes: {s}", .{arg});
            return 1;
        };

        if (mins > 59) {
            std.log.err("Minutes number {d} is too big", .{mins});
            return 1;
        }

        const mins1: hl.Time = .{ .tmins = 60 * hours + mins };

        const interval: hl.Interval = hl.Interval.new(mins0, mins1) catch |err| switch (err) {
            error.NegativeDelta => {
                var buf: [10]u8 = undefined;
                std.log.err(
                    "Wrong Delta: {s} -> {s}",
                    .{ mins0.print(buf[0..5]), mins1.print(buf[5..10]) },
                );
                return 1;
            },
        };

        if (is_last) try list.append(interval);
        is_last = !is_last;

        mins0 = mins1;
    }

    if (is_last) {
        var buf: [5]u8 = undefined;
        std.log.warn("Missing last entry. Ignoring value {s}.", .{mins0.print(&buf)});
    }

    const intervals: []const hl.Interval = try list.toOwnedSlice();
    defer gpa.free(intervals);

    var mins_sum: u32 = 0;
    for (intervals) |interval| mins_sum += interval.delta();

    const total_time: hl.Time = .{ .tmins = mins_sum };

    const now: c.time_t = c.time(null);
    const tm_ptr: [*c]c.tm = c.localtime(&now);
    var date_buf: [11]u8 = undefined;
    const n = c.strftime(&date_buf, date_buf.len, "%Y-%m-%d", tm_ptr);
    if (n != date_buf.len - 1) {
        std.log.err("strftime", .{});
        return 1;
    }

    var buf2: [5]u8 = undefined;
    stdout.print(
        "{s} {s} |",
        .{ date_buf[0 .. date_buf.len - 1 :0], total_time.print(&buf2) },
    ) catch return 1;

    var buf3: [10]u8 = undefined;
    for (intervals) |interval| stdout.print(
        " {s} {s}",
        .{ interval.t0.print(buf3[0..5]), interval.t1.print(buf3[5..10]) },
    ) catch return 1;

    stdout.print("\n", .{}) catch return 1;

    return 0;
}
