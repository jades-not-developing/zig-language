const std = @import("std");
const LexicalToken = @import("lexer.zig").LexicalToken;

pub const ArithmaticOperation = enum { add, sub, mul, div };

pub const ExprTag = enum {
    binary_expr,
    numeric_literal,
};

pub const Expr = union(ExprTag) {
    binary_expr: struct {
        lhs: *Expr,
        operation: ArithmaticOperation,
        rhs: *Expr,
    },
    numeric_literal: u32,
};

pub const Parser = struct {
    cursor: usize,
    contents: []const LexicalToken,
    arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator),
    const Self = @This();

    pub fn new(tokens: []const LexicalToken) Self {
        return Self{
            .cursor = 0,
            .contents = tokens,
        };
    }

    pub fn parse(self: *Self) ![]const Expr {
        const expressions = std.ArrayList(Expr).init(std.heap.page_allocator);
        while (self.peek(null)) |token| {
            _ = token;

            if (try self.parseBinaryExpr()) |bin_expr| {
                std.debug.print("{any}", .{bin_expr});
                _ = self.consume();
            }
        }

        return expressions.items;
    }

    fn parseBinaryExpr(self: *Self) !?Expr {
        const allocator = self.arena.allocator();
        if (self.parseNumericLiteral()) |lhs| {
            var operation: ?ArithmaticOperation = null;
            if (self.peek(null)) |token| {
                switch (token) {
                    LexicalToken.plus => operation = ArithmaticOperation.add,
                    //LexicalToken.minus => operation = ArithmaticOperation.sub,
                    //LexicalToken.slash => operation = ArithmaticOperation.div,
                    //LexicalToken.star => operation = ArithmaticOperation.mul,
                    else => {},
                }
                if (operation) |op| {
                    _ = self.consume();
                    if (self.parseNumericLiteral()) |rhs| {
                        var lhs_expr_list: []Expr = try allocator.alloc(Expr, 1);
                        var rhs_expr_list: []Expr = try allocator.alloc(Expr, 1);

                        lhs_expr_list[0] = lhs;
                        rhs_expr_list[0] = rhs;

                        return Expr{ .binary_expr = .{
                            .lhs = &lhs_expr_list[0],
                            .rhs = &rhs_expr_list[0],
                            .operation = op,
                        } };
                    } else {
                        std.debug.panic("Failed to parse BinaryExpr: invalid rhs", .{});
                    }
                }
            }
        }

        return null;
    }

    fn parseNumericLiteral(self: *Self) ?Expr {
        const currentToken = self.contents[self.cursor];
        switch (currentToken) {
            LexicalToken.number => |num| {
                _ = self.consume();

                return Expr{
                    .numeric_literal = num,
                };
            },
            else => {
                return null;
            },
        }
    }

    fn peek(self: Self, offset: ?usize) ?LexicalToken {
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

    fn consume(self: *Self) ?LexicalToken {
        if (self.peek(null)) |c| {
            self.cursor += 1;
            return c;
        }

        return null;
    }
};

test "can parse basic expression" {
    var parser = Parser.new(&[_]LexicalToken{
        LexicalToken{ .number = 2 },
        LexicalToken.plus,
        LexicalToken{ .number = 3 },
    });

    const expressions = parser.parse();
    try std.testing.expectEqual(expressions.len, 1);

    std.debug.print("\n{any}\n", .{expressions});

    const expr = expressions[0];
    try std.testing.expectEqual(expr.binary_expr.lhs.numeric_literal, 2);
    try std.testing.expectEqual(expr.binary_expr.rhs.numeric_literal, 3);
}
