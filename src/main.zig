const std = @import("std");

pub fn main() !void {}

test {
    @import("std").testing.refAllDecls(@This());
}
