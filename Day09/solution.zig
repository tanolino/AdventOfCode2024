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

    const copy = try alloc.alloc(i32, content.len);
    defer alloc.free(copy);
    for (0..content.len) |i| {
        copy[i] = content[i];
    }

    const result = resolve(content);
    const result2 = try resolve2(copy);

    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d} | {d}\n", .{ filename, result, result2 });
}

pub fn main() anyerror!void {
    // p1: 1928
    // p2: 2858
    try solve("part1.example.txt");

    // p1: 6200294120911
    // p2: 6227018762750
    try solve("part1.test.txt");
}

fn print_content(content: []const i32) !void {
    const cout = std.io.getStdOut().writer();
    try cout.print("\t", .{});
    for (content) |c| {
        if (c >= 0) {
            try cout.print("{d}", .{c});
        } else {
            try cout.print("-", .{});
        }
    }
    try cout.print("\n", .{});
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

fn resolve2(data: []i32) !usize {
    {
        // try print_content(data);
        var i: i32 = std.mem.max(i32, data);
        while (i >= 0) {
            one_move(data, i);
            // try print_content(data);
            i -= 1;
        }
    }

    // Checksum
    var checksum: usize = 0;
    for (0..data.len) |i| {
        const val = data[i];
        if (val > 0) {
            const num: usize = @intCast(val);
            checksum += num * i;
        }
    }
    return checksum;
}

fn one_move(data: []i32, value: i32) void {
    var beg: usize = data.len;
    var end: usize = 0;

    // Maybe optimize
    for (0..data.len) |i| {
        if (data[i] == value) {
            beg = @min(beg, i);
            end = @max(end, i);
        }
    }

    if (beg > end) {
        return;
    }

    const data_size = 1 + end - beg;

    var free_beg: usize = 0;
    while (free_beg < beg) {
        if (data[free_beg] >= 0) {
            free_beg += 1;
            continue;
        }

        var free_end = free_beg + 1;
        while (data[free_end] < 0) {
            free_end += 1;
        }
        const free_size = free_end - free_beg;
        if (free_size >= data_size) {
            for (0..data_size) |i| {
                const val = data[beg + i];
                data[beg + i] = data[free_beg + i];
                data[free_beg + i] = val;
            }
            return;
        } else {
            // Search for the next free mem
            free_beg = free_end;
        }
    }
}
