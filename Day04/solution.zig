const std = @import("std");

fn right_trim(buff: []const u8) []const u8 {
    var tmp: []const u8 = buff[0..];
    while (tmp.len > 0 and (tmp[tmp.len - 1] == '\n' or tmp[tmp.len - 1] == '\r')) {
        tmp.len -= 1;
    }
    return tmp;
}

fn read_all_file(filename: []const u8, allocator: *const std.mem.Allocator) anyerror![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const stat = try file.stat();
    var buffer = try allocator.alloc(u8, stat.size);

    const read_size = try file.readAll(buffer);
    if (read_size < buffer.len) {
        buffer.len = read_size;
    }

    return buffer;
}

fn count_rows(text: []const u8) usize {
    var res: usize = 0;
    var split = std.mem.split(u8, text, "\n");
    while (split.next()) |line| {
        if (right_trim(line).len > 1) {
            res += 1;
        }
    }
    return res;
}

fn count_columns(text: []const u8) usize {
    var res: usize = 0;
    var split = std.mem.split(u8, text, "\n");
    while (split.next()) |line| {
        const trimmed = right_trim(line);
        if (res == 0) {
            res = trimmed.len;
        } else if (trimmed.len > 1) {
            res = @min(res, trimmed.len);
        }
    }
    return res;
}

const DataSet = struct { rows: usize, cols: usize, data: []u8 };

fn parse_content(text: []const u8, allocator: *const std.mem.Allocator) !DataSet {
    const rows = count_rows(text);
    const cols = count_columns(text);

    var res = DataSet{
        .rows = rows,
        .cols = cols,
        .data = try allocator.alloc(u8, rows * cols),
    };

    var split = std.mem.split(u8, text, "\n");
    var r: usize = 0;
    while (split.next()) |line| {
        if (right_trim(line).len > 1) {
            for (0..cols) |c| {
                res.data[r * cols + c] = line[c];
            }
            r += 1;
        }
    }
    return res;
}

const text_XMAS = "XMAS";

fn count_xmas(data: *const DataSet) usize {
    const rows = data.rows;
    const cols = data.cols;
    var res: usize = 0;

    for (0..rows) |r| {
        for (0..cols) |c| {
            for (0..8) |dir| {
                for (0..text_XMAS.len) |letter_nr| {
                    var c2 = c;
                    var r2 = r;
                    if (dir % 4 >= 1) {
                        if (dir > 4) {
                            // c2 -= letter_nr;
                            const subs = @subWithOverflow(c2, letter_nr);
                            if (subs[1] == 1) {
                                continue;
                            }
                            c2 = subs[0];
                        } else {
                            c2 += letter_nr;
                        }
                    }
                    if (c2 >= cols) continue;

                    if (dir < 2 or dir > 6) {
                        // r2 -= letter_nr;
                        const subs = @subWithOverflow(r2, letter_nr);
                        if (subs[1] == 1) {
                            continue;
                        }
                        r2 = subs[0];
                    } else if (dir > 2 and dir < 6) {
                        r2 += letter_nr;
                    }
                    if (r2 >= rows) continue;

                    if (data.data[r2 * data.cols + c2] != text_XMAS[letter_nr]) {
                        break;
                    } else if (letter_nr == text_XMAS.len - 1) {
                        res += 1;
                    }
                }
            }
        }
    }

    return res;
}

fn process_input(filename: []const u8) anyerror!void {
    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const allocator = gp.allocator();

    const file_content = try read_all_file(filename, &allocator);
    defer allocator.free(file_content);

    const data = try parse_content(file_content, &allocator);
    defer allocator.free(data.data);

    const cout = std.io.getStdOut().writer();
    if (false) {
        for (0..data.rows) |r| {
            try cout.print("\t", .{});
            for (0..data.cols) |c| {
                try cout.print("{s}", .{data.data[r * data.cols + c .. r * data.cols + c + 1]});
            }
            try cout.print("\n", .{});
        }
    }

    const result = count_xmas(&data);

    // const cout = std.io.getStdOut().writer();
    try cout.print("File {s} counts {d} XMAS\n", .{ filename, result });
}

pub fn main() anyerror!void {
    try process_input("part1.example.txt"); // 18
    try process_input("part1.test.txt"); // 2462
}
