const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;

pub fn main() !void {
    var lexer = Lexer.new("52 + 7");
    const tokens = try lexer.analyze();

    var parser = Parser.new(tokens);
    const expressions = try parser.parse();

    std.debug.print("{any}", .{expressions});
}

test {
    @import("std").testing.refAllDecls(@This());
}
