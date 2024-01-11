const std = @import("std");

pub const LexicalTokenTag = enum {
    number,
    plus,
    eof,
    open_paren,
    close_paren,
    semi,
};

pub const LexicalToken = union(LexicalTokenTag) {
    number: u32,
    plus: void,
    eof: void,
    open_paren: void,
    close_paren: void,
    semi: void,
};

fn isDigit(input: u8) bool {
    return input >= '0' and input <= '9';
}

pub fn printLexicalTokenList(list: []const LexicalToken) void {
    std.debug.print("{{\n", .{});
    for (list) |item| {
        switch (item) {
            LexicalToken.number => |number| std.debug.print("  Number({d}),\n", .{number}),
            LexicalToken.plus => std.debug.print("  Plus,\n", .{}),
            LexicalToken.eof => std.debug.print("  EOF,\n", .{}),
            LexicalToken.open_paren => std.debug.print("  OpenParen,\n", .{}),
            LexicalToken.close_paren => std.debug.print("  CloseParen,\n", .{}),
            LexicalToken.semi => std.debug.print("  Semi,\n", .{}),
        }
    }
    std.debug.print("}}\n", .{});
}

pub const Lexer = struct {
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
                '(' => {
                    _ = self.consume();
                    try tokens.append(LexicalToken.open_paren);
                },
                ')' => {
                    _ = self.consume();
                    try tokens.append(LexicalToken.close_paren);
                },
                ';' => {
                    _ = self.consume();
                    try tokens.append(LexicalToken.semi);
                },
                ' ', '\t' => {
                    _ = self.consume();
                },
                else => {
                    std.debug.panic("Unrecognized token `{c}`", .{c});
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

test "can lex basic expression" {
    var lexer = Lexer.new("(51 + 7);");
    const analysis = try lexer.analyze();

    printLexicalTokenList(analysis);

    try std.testing.expectEqual(analysis.len, 7);
    try std.testing.expectEqual(@as(LexicalTokenTag, analysis[0]), LexicalTokenTag.open_paren);
    try std.testing.expectEqual(analysis[1], .{ .number = 51 });
    try std.testing.expectEqual(@as(LexicalTokenTag, analysis[2]), LexicalTokenTag.plus);
    try std.testing.expectEqual(analysis[3], .{ .number = 7 });
    try std.testing.expectEqual(@as(LexicalTokenTag, analysis[4]), LexicalTokenTag.close_paren);
    try std.testing.expectEqual(@as(LexicalTokenTag, analysis[5]), LexicalTokenTag.semi);
    try std.testing.expectEqual(@as(LexicalTokenTag, analysis[6]), LexicalTokenTag.eof);
}
