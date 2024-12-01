const std = @import("std");

const WorkSet = struct { arr: [2][]i64 };

pub fn free_WorkSet(workSet: *WorkSet, allocator: std.mem.Allocator) void {
    for (0..2) |i| {
        allocator.free(workSet.arr[i]);
    }
}

pub fn right_trim(buff: []const u8) []const u8 {
    var tmp: []const u8 = buff[0..];
    while (tmp.len > 0 and (tmp[tmp.len - 1] == '\n' or tmp[tmp.len - 1] == '\r')) {
        tmp.len -= 1;
    }
    return tmp;
}

pub fn read_input(filename: []const u8, allocator: std.mem.Allocator) !WorkSet {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const stat = try file.stat();
    var buffer = try allocator.alloc(u8, stat.size);
    defer allocator.free(buffer);
    const read_size = try file.readAll(buffer);
    if (read_size < buffer.len) {
        buffer.len = read_size;
    }

    var line_count: usize = 0;
    var splits = std.mem.split(u8, buffer, "\n");
    while (splits.next()) |line| {
        if (line.len > 1) {
            line_count += 1;
        }
    }
    splits.reset();

    var pos: usize = 0;
    var arr: [2][]i64 = .{ try allocator.alloc(i64, line_count), try allocator.alloc(i64, line_count) };
    while (splits.next()) |line| {
        if (line.len > 1) {
            const tmp = right_trim(line);
            var splits2 = std.mem.split(u8, tmp, " ");

            var arr_id: u8 = 0;
            while (splits2.next()) |number| {
                if (arr_id < 2 and number.len > 0) {
                    arr[arr_id][pos] = try std.fmt.parseInt(i64, number, 10);
                    arr_id += 1;
                }
            }
            pos += 1;
        }
    }

    return WorkSet{ .arr = arr };
}

pub fn solve_file(filename: []const u8) !void {
    const cout = std.io.getStdOut().writer();
    try cout.print("Input: \"{s}\"\n", .{filename});

    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const allocator = gp.allocator();

    var data = try read_input(filename, allocator);
    defer free_WorkSet(&data, allocator);

    for (0..2) |i| {
        std.mem.sort(i64, data.arr[i], {}, comptime std.sort.asc(i64));
    }

    const end = @min(data.arr[0].len, data.arr[1].len);
    var distance: i64 = 0;
    for (0..end) |i| {
        // try cout.print("CMP {d} {d}\n", .{ data.arr[0][i], data.arr[1][i] });
        const diff: i64 = data.arr[0][i] - data.arr[1][i];
        if (diff > 0) {
            distance += diff;
        } else {
            distance -= diff;
        }
    }

    try cout.print("Solution: {d}\n", .{distance});
}

pub fn main() anyerror!void {
    try solve_file("part1.example.txt");
    try solve_file("part1.test.txt");
}
