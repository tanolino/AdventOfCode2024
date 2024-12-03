const std = @import("std");

const State = enum { Mul, Num1, Sep, Num2 };
const mul = "mul(";
const do = "do()";
const dont = "don't()";

fn IsNum(c: u8) bool {
    return switch (c) {
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => true,
        else => false,
    };
}

fn get_dont(beginning: []const u8) bool {
    if (beginning.len < dont.len) {
        return false;
    } else {
        return std.mem.eql(u8, beginning[0..dont.len], dont);
    }
}

fn get_do(beginning: []const u8) bool {
    if (beginning.len < do.len) {
        return false;
    } else {
        return std.mem.eql(u8, beginning[0..do.len], do);
    }
}

fn get_mul(beginning: []const u8) anyerror!usize {
    if (beginning.len <= 8) {
        return 0;
    }

    for (0..mul.len) |i| {
        if (beginning[i] != mul[i]) {
            return 0;
        }
    }

    var num1: []const u8 = beginning[4..4];
    for (0..3) |i| {
        if (IsNum(beginning[4 + i])) {
            num1 = beginning[4 .. 5 + i];
        } else {
            break;
        }
    }
    if (num1.len == 0 or beginning[4 + num1.len] != ',') {
        return 0;
    }

    const num2_start = 5 + num1.len;
    var num2: []const u8 = beginning[num2_start..num2_start];
    for (0..3) |i| {
        if (num2_start + i >= beginning.len) {
            return 0;
        } else if (IsNum(beginning[num2_start + i])) {
            num2 = beginning[num2_start .. num2_start + 1 + i];
        } else {
            break;
        }
    }
    // access max 12
    if (num2.len == 0 or beginning[mul.len + num1.len + num2.len + 1] != ')') {
        return 0;
    }

    return try std.fmt.parseInt(usize, num1, 10) * try std.fmt.parseInt(usize, num2, 10);
}

fn line(input: []const u8) anyerror!usize {
    var sum: usize = 0;
    var tmp = input[0..];
    while (tmp.len > mul.len) {
        sum += try get_mul(tmp);
        tmp = tmp[1..];
    }
    return sum;
}

fn line2(input: []const u8) anyerror!usize {
    var sum: usize = 0;
    var mul_enabled: bool = true;
    var tmp = input[0..];
    while (tmp.len > mul.len) {
        if (mul_enabled) {
            sum += try get_mul(tmp);
            mul_enabled = mul_enabled and !get_dont(tmp);
        } else {
            mul_enabled = mul_enabled or get_do(tmp);
        }

        tmp = tmp[1..];
    }
    return sum;
}

fn right_trim(buff: []const u8) []const u8 {
    var tmp: []const u8 = buff[0..];
    while (tmp.len > 0 and (tmp[tmp.len - 1] == '\n' or tmp[tmp.len - 1] == '\r')) {
        tmp.len -= 1;
    }
    return tmp;
}

const Result = struct { part1: usize, part2: usize };

pub fn process_input(filename: []const u8) anyerror!Result {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const allocator = gp.allocator();

    const stat = try file.stat();
    var buffer = try allocator.alloc(u8, stat.size);
    defer allocator.free(buffer);

    const read_size = try file.readAll(buffer);
    if (read_size < buffer.len) {
        buffer.len = read_size;
    }
    const tmp = right_trim(buffer);
    return Result{
        .part1 = try line(tmp),
        .part2 = try line2(tmp),
    };
}

pub fn solve_file(filename: []const u8) !void {
    const p = try process_input(filename);
    const cout = std.io.getStdOut().writer();
    try cout.print("Input: \"{s}\"  {d}  |  {d}\n", .{ filename, p.part1, p.part2 });
}

pub fn main() anyerror!void {
    try solve_file("part1.example.txt");
    try solve_file("part2.example.txt");
    try solve_file("part1.test.txt"); // 661 too low
}
