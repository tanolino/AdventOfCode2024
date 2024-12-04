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

fn count_xmas_part1(data: *const DataSet) usize {
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

// x is expected to be over 1
// rotation is expected to be 0..8
fn get_d_x(x: usize, rotation: usize) usize {
    const r = rotation % 4;
    if (r < 2) {
        return x + 1;
    } else {
        return x - 1;
    }
}

// x is expected to be over 1
// rotation is expected to be 0..8
fn get_d_y(y: usize, rotation: usize) usize {
    const r = rotation % 4;
    if (r == 1 or r == 2) {
        return y + 1;
    } else {
        return y - 1;
    }
}

const text_MAS = "MAS";

fn count_xmas_part2(data: *const DataSet) usize {
    const rows = data.rows;
    const cols = data.cols;
    var res: usize = 0;

    for (1..rows - 1) |r| {
        for (1..cols - 1) |c| {
            var r2 = r;
            var c2 = c;
            if (data.data[r2 * cols + c2] != text_MAS[1]) {
                continue;
            }
            for (0..4) |dir| {
                r2 = get_d_y(r, dir);
                c2 = get_d_x(c, dir);
                if (data.data[r2 * cols + c2] != text_MAS[0]) {
                    continue;
                }
                r2 = get_d_y(r, dir + 1);
                c2 = get_d_x(c, dir + 1);
                if (data.data[r2 * cols + c2] != text_MAS[0]) {
                    continue;
                }
                r2 = get_d_y(r, dir + 2);
                c2 = get_d_x(c, dir + 2);
                if (data.data[r2 * cols + c2] != text_MAS[2]) {
                    continue;
                }
                r2 = get_d_y(r, dir + 3);
                c2 = get_d_x(c, dir + 3);
                if (data.data[r2 * cols + c2] != text_MAS[2]) {
                    continue;
                }

                res += 1;
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

    const p1 = count_xmas_part1(&data);
    const p2 = count_xmas_part2(&data);

    // const cout = std.io.getStdOut().writer();
    try cout.print("File {s} counts {d} XMAS and {d} X-MAS\n", .{ filename, p1, p2 });
}

pub fn main() anyerror!void {
    try process_input("part1.example.txt"); // p1: 18 / p2: 9
    try process_input("part1.test.txt"); // p1: 2462 / p2: 1877
}
