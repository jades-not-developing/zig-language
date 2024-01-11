const std = @import("std");

const LexicalTokenTag = enum {
    number,
    plus,
    eof,
};

const LexicalToken = union(LexicalTokenTag) {
    number: u32,
    plus: void,
    eof: void,
};

const Lexer = struct {
    cursor: usize,
    contents: []const u8,

    const Self = @This();

    pub fn new(contents: []const u8) Self {
        return Self{
            .cursor = 0,
            .contents = contents,
        };
    }

    pub fn analyze(self: *Self) []const LexicalToken {
        _ = self;
        return &[_]LexicalToken{};
    }

    fn peek(self: Self, offset: ?usize) ?u8 {
        var cursorOffset: usize = 0;
        if (offset) |off| {
            cursorOffset = off;
        }

        const contentsOffset = self.cursor + cursorOffset;
        if (contentsOffset > self.contents.len) {
            return null;
        }

        return self.contents[contentsOffset];
    }

    fn consume(self: *Self) ?u8 {
        if (self.peek(null)) |c| {
            self.cursor += 1;
            return c;
        }

        return null;
    }
};

pub fn main() !void {}

test "can lex basic expression" {
    var lexer = Lexer.new("5 + 7");
    const analysis = lexer.analyze();

    try std.testing.expectEqual(analysis.len, 4);
    try std.testing.expectEqual(analysis[0], .{ .number = 5 });
    try std.testing.expectEqual(@as(LexicalTokenTag, analysis[1]), LexicalTokenTag.plus);
    try std.testing.expectEqual(analysis[2], .{ .number = 7 });
    try std.testing.expectEqual(@as(LexicalTokenTag, analysis[3]), LexicalTokenTag.eof);
}
