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

fn isDigit(input: u8) bool {
    return input >= '0' and input <= '9';
}

fn printLexicalTokenList(list: []const LexicalToken) void {
    std.debug.print("{{\n", .{});
    for (list) |item| {
        switch (item) {
            LexicalToken.number => |number| std.debug.print("  Number({d}),\n", .{number}),
            LexicalToken.plus => std.debug.print("  Plus,\n", .{}),
            LexicalToken.eof => std.debug.print("  EOF,\n", .{}),
        }
    }
    std.debug.print("}}\n", .{});
}

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

    pub fn analyze(self: *Self) ![]const LexicalToken {
        var tokens = std.ArrayList(LexicalToken).init(std.heap.page_allocator);
        while (self.peek(null)) |c| {
            switch (c) {
                '0'...'9' => {
                    var numString = std.ArrayList(u8).init(std.heap.page_allocator);
                    try numString.append(self.consume().?);
                    while (self.peek(null)) |c2| {
                        if (!isDigit(c2)) {
                            break;
                        }

                        try numString.append(self.consume().?);
                    }

                    try tokens.append(.{
                        .number = try std.fmt.parseInt(u32, numString.items, 10),
                    });
                },
                '+' => {
                    _ = self.consume();
                    try tokens.append(LexicalToken.plus);
                },
                else => {
                    _ = self.consume();
                },
            }
        }

        try tokens.append(LexicalToken.eof);

        return tokens.items;
    }

    fn peek(self: Self, offset: ?usize) ?u8 {
        var cursorOffset: usize = 0;
        if (offset) |off| {
            cursorOffset = off;
        }

        const contentsOffset = self.cursor + cursorOffset;
        if (contentsOffset >= self.contents.len) {
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
    var lexer = Lexer.new("51 + 7");
    const analysis = try lexer.analyze();

    printLexicalTokenList(analysis);

    try std.testing.expectEqual(analysis.len, 4);
    try std.testing.expectEqual(analysis[0], .{ .number = 51 });
    try std.testing.expectEqual(@as(LexicalTokenTag, analysis[1]), LexicalTokenTag.plus);
    try std.testing.expectEqual(analysis[2], .{ .number = 7 });
    try std.testing.expectEqual(@as(LexicalTokenTag, analysis[3]), LexicalTokenTag.eof);
}
