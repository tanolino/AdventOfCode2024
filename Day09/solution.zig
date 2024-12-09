const std = @import("std");

fn right_trim(buff: []const u8) []const u8 {
    var tmp: []const u8 = buff[0..];
    while (tmp.len > 0 and (tmp[tmp.len - 1] == '\n' or tmp[tmp.len - 1] == '\r')) {
        tmp.len -= 1;
    }
    return tmp;
}

fn read_all_file(filename: []const u8, alloc: *const std.mem.Allocator) anyerror![]i32 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const stat = try file.stat();
    var buffer = try alloc.alloc(u8, stat.size);
    defer alloc.free(buffer);

    const read_size = try file.readAll(buffer);
    if (read_size < buffer.len) {
        buffer.len = read_size;
    }

    const trimmed = right_trim(buffer);
    var mem_len: usize = 0;
    for (trimmed) |c| {
        const pos: u8 = c - '0'; // or panic on wrong input
        try std.testing.expect(pos <= 9); // or panic on wrong input

        mem_len += pos;
    }

    var memory = try alloc.alloc(i32, mem_len);
    var write_pos: usize = 0;
    var id: i32 = 0;
    var data_or_empty: bool = true;
    for (trimmed) |c| {
        const pos: u8 = c - '0'; // or panic on wrong input
        try std.testing.expect(pos <= 9); // or panic on wrong input

        var char: i32 = -1;
        if (data_or_empty) {
            char = id;
            id += 1;
        }
        data_or_empty = !data_or_empty;

        for (0..pos) |_| {
            memory[write_pos] = char;
            write_pos += 1;
        }
    }

    return memory;
}

fn solve(filename: []const u8) !void {
    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const alloc = gp.allocator();

    const content = try read_all_file(filename, &alloc);
    defer alloc.free(content);

    const result = resolve(content);

    // Some debugging
    if (false) {
        const cout = std.io.getStdOut().writer();
        try cout.print("\t", .{});
        for (content) |c| {
            if (c >= 0) {
                try cout.print("{d}", .{c});
            } else {
                try cout.print("-", .{});
            }
        }
    }

    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d}\n", .{ filename, result });
}

pub fn main() anyerror!void {
    // p1: 1928
    // p2:
    try solve("part1.example.txt");

    // p1: 6200294120911
    // p2:
    try solve("part1.test.txt");
}

fn resolve(data: []i32) usize {
    var beg: usize = 0;
    var end: usize = data.len - 1;

    while (true) {
        while (data[beg] >= 0 and beg < end) {
            beg += 1;
        }
        while (data[end] < 0 and beg < end) {
            end -= 1;
        }

        if (beg < end) {
            const val = data[beg];
            data[beg] = data[end];
            data[end] = val;
        } else {
            break;
        }
    }

    // Checksum
    var checksum: usize = 0;
    for (0..data.len) |i| {
        const val = data[i];
        if (val < 0) {
            break;
        }
        const num: usize = @intCast(val);
        checksum += num * i;
    }
    return checksum;
}
