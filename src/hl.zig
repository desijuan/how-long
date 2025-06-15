const std = @import("std");

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

pub const Interval = struct {
    t0: Time,
    t1: Time,

    pub fn new(t0: Time, t1: Time) error{NegativeDelta}!Interval {
        return if (t1.tmins < t0.tmins)
            error.NegativeDelta
        else
            Interval{ .t0 = t0, .t1 = t1 };
    }

    pub fn delta(self: Interval) u32 {
        return self.t1.tmins - self.t0.tmins;
    }
};
