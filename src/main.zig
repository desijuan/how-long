const std = @import("std");
const c = @cImport(@cInclude("time.h"));

pub const std_options = std.Options{
    .log_level = .info,
};

const Gpa: type = @import("allocator.zig").Gpa;

pub fn main() error{OutOfMemory}!u8 {
    defer if (comptime @hasDecl(Gpa, "deinit")) Gpa.deinit();
    const gpa = Gpa.allocator();

    var bw = std.io.BufferedWriter(256, std.fs.File.Writer){
        .unbuffered_writer = std.io.getStdOut().writer(),
    };
    defer bw.flush() catch {};

    const stdout = bw.writer();

    var args: std.process.ArgIterator = try std.process.argsWithAllocator(gpa);
    _ = args.next().?;

    const punches: []const Time = parseArgs(gpa, &args) catch return 1;
    defer gpa.free(punches);

    const total_time: Time = sumDeltas(punches) catch return 1;

    const now: c.time_t = c.time(null);
    const tm_ptr: [*c]c.tm = c.localtime(&now);
    var buf_date: [11]u8 = undefined;
    const n = c.strftime(&buf_date, buf_date.len, "%Y-%m-%d", tm_ptr);
    if (n != buf_date.len - 1) {
        std.log.err("strftime", .{});
        return 1;
    }

    var buf_time: [5]u8 = undefined;

    stdout.print(
        "{s} {s} |",
        .{ buf_date[0 .. buf_date.len - 1 :0], total_time.print(&buf_time) },
    ) catch return 1;

    for (punches) |punch|
        stdout.print(" {s}", .{punch.print(&buf_time)}) catch return 1;

    stdout.print("\n", .{}) catch return 1;

    return 0;
}

pub const Time = struct {
    tmins: u32,

    pub inline fn hours(self: Time) u32 {
        return self.tmins / 60;
    }

    pub inline fn mins(self: Time) u32 {
        return self.tmins % 60;
    }

    pub fn print(self: Time, buf: *[5]u8) []u8 {
        return std.fmt.bufPrint(
            buf,
            "{d:0>2}:{d:0>2}",
            .{ self.hours(), self.mins() },
        ) catch unreachable;
    }
};

const ProcessArgsError = error{
    Expecting4Digits,
    UnableToParseHours,
    HoursNumberTooBig,
    UnableToParseMinutes,
    MinutesNumberTooBig,
};

fn parseArgs(
    gpa: std.mem.Allocator,
    args: *std.process.ArgIterator,
) (error{OutOfMemory} || ProcessArgsError)![]const Time {
    var list = try std.ArrayList(Time).initCapacity(gpa, 32);
    errdefer list.deinit();

    var buf: [4]u8 = undefined;

    while (args.next()) |arg| {
        const str: []const u8 = switch (arg.len) {
            3, 4 => std.fmt.bufPrint(&buf, "{s:0>4}", .{arg}) catch unreachable,

            else => |len| {
                std.log.err("Expecting 4 digits, got {d}: {s}", .{ len, arg });
                return error.Expecting4Digits;
            },
        };

        const hours_str: *const [2]u8 = str[0..2];
        const mins_str: *const [2]u8 = str[2..4];

        const hours: u32 = std.fmt.parseInt(u32, hours_str, 10) catch {
            std.log.err("Unable to parse hours: {s}", .{arg});
            return error.UnableToParseHours;
        };

        if (hours > 23) {
            std.log.err("Hours number {d} is too big", .{hours});
            return error.HoursNumberTooBig;
        }

        const mins: u32 = std.fmt.parseInt(u32, mins_str, 10) catch {
            std.log.err("Unable to parse minutes: {s}", .{arg});
            return error.UnableToParseMinutes;
        };

        if (mins > 59) {
            std.log.err("Minutes number {d} is too big", .{mins});
            return error.MinutesNumberTooBig;
        }

        try list.append(Time{ .tmins = 60 * hours + mins });
    }

    return try list.toOwnedSlice();
}

fn sumDeltas(punches: []const Time) error{NegativeDelta}!Time {
    var mins_sum: u32 = 0;
    var punch0: Time = undefined;

    for (punches, 0..) |punch, i| {
        if (i % 2 == 0) {
            punch0 = punch;
            continue;
        }

        if (punch.tmins < punch0.tmins) {
            var buf: [10]u8 = undefined;
            std.log.err(
                "Negative Delta: {s} -> {s}",
                .{ punch0.print(buf[0..5]), punch.print(buf[5..10]) },
            );
            return error.NegativeDelta;
        }

        mins_sum += punch.tmins - punch0.tmins;
    }

    if (punches.len % 2 != 0) {
        var buf: [5]u8 = undefined;
        std.log.warn("Missing last entry. Ignoring value {s}.", .{punch0.print(&buf)});
    }

    return Time{ .tmins = mins_sum };
}
