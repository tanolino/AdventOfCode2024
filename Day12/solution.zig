const std = @import("std");

fn right_trim(buff: []const u8) []const u8 {
    var tmp: []const u8 = buff[0..];
    while (tmp.len > 0 and (tmp[tmp.len - 1] == '\n' or tmp[tmp.len - 1] == '\r')) {
        tmp.len -= 1;
    }
    return tmp;
}

fn read_all_file(filename: []const u8, alloc: *const std.mem.Allocator) anyerror![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const stat = try file.stat();
    var buffer = try alloc.alloc(u8, stat.size);

    const read_size = try file.readAll(buffer);
    if (read_size < buffer.len) {
        buffer.len = read_size;
    }
    return buffer;
}

fn solve(filename: []const u8) !void {
    //var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    //defer _ = gp.deinit();
    //const alloc = gp.allocator();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const content = try read_all_file(filename, &alloc);
    defer alloc.free(content);

    const field = try create_field(content, &alloc);
    defer alloc.free(field.data);

    // try print_field(&field);
    const result = resolve(&field);

    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d}\n", .{ filename, result });
}

pub fn main() anyerror!void {
    try solve("part1.example.140.txt"); // 140 / 80
    // try solve("part1.example.772.txt"); // 772 / 436
    // try solve("part1.example.1930.txt"); // 1930 / 368
    // try solve("part1.test.txt"); // 1546338
}

fn print_field(field: *const Field) !void {
    const cout = std.io.getStdOut().writer();
    for (0..field.data.len) |i| {
        if (i % field.width == 0) {
            try cout.print("\n", .{});
        }
        if (field.data[i] == 0) {
            try cout.print("-", .{});
        } else {
            try cout.print("{s}", .{field.data[i .. i + 1]});
        }
    }
    try cout.print("\n", .{});
}

fn create_field(content: []const u8, alloc: *const std.mem.Allocator) !Field {
    const trimmed = right_trim(content);
    var iter = std.mem.split(u8, trimmed, "\n");
    var line_count: usize = 0;
    var line_width: usize = 0;
    while (iter.next()) |txt| {
        const txt2 = right_trim(txt);
        if (txt2.len >= 1) {
            line_count += 1;
            if (line_width == 0 or txt2.len < line_width) {
                line_width = txt2.len;
            }
        }
    }

    // Padding
    line_width += 2;
    line_count += 2;
    var res = Field{
        .width = line_width,
        .height = line_count,
        .data = try alloc.alloc(u8, line_count * line_width),
    };
    iter.reset();
    for (0..res.width) |i| {
        res.data[i] = 0;
    }
    line_count = res.width;
    while (iter.next()) |txt| {
        const txt2 = right_trim(txt);
        if (txt2.len >= 1) {
            const start = res.data[line_count..];
            start[0] = 0;
            std.mem.copyForwards(u8, start[1..], txt2);
            start[res.width - 1] = 0;
            line_count += res.width;
        }
    }
    for (0..res.width) |i| {
        res.data[line_count + i] = 0;
    }
    return res;
}

const Field = struct {
    width: usize,
    height: usize,
    data: []u8,
};

fn resolve(field: *const Field) usize {
    var res: usize = 0;
    for (field.width + 1..field.data.len - field.width) |i| {
        if (field.data[i] != 0) {
            const r = flood(field, i);
            clean(field, i);
            // const cout = std.io.getStdOut().writer();
            // try cout.print("Status: Area {d} Perims {d} | {d}\n", .{ r[0], r[1], p2 });
            res += r[0] * r[1];
        }
    }
    return res;
}

fn flood(field: *const Field, index: usize) [2]usize {
    var area: usize = 1;
    var perim: usize = 0;
    const iam = field.data[index];
    field.data[index] = 1;

    var test_pos: usize = index + 1;
    if (field.data[test_pos] == iam) {
        const r = flood(field, test_pos);
        area += r[0];
        perim += r[1];
    } else if (field.data[test_pos] != 1) {
        perim += 1;
    }
    test_pos = index - 1;
    if (field.data[test_pos] == iam) {
        const r = flood(field, test_pos);
        area += r[0];
        perim += r[1];
    } else if (field.data[test_pos] != 1) {
        perim += 1;
    }
    test_pos = index + field.width;
    if (field.data[test_pos] == iam) {
        const r = flood(field, test_pos);
        area += r[0];
        perim += r[1];
    } else if (field.data[test_pos] != 1) {
        perim += 1;
    }
    test_pos = index - field.width;
    if (field.data[test_pos] == iam) {
        const r = flood(field, test_pos);
        area += r[0];
        perim += r[1];
    } else if (field.data[test_pos] != 1) {
        perim += 1;
    }

    return .{ area, perim };
}

const Dir = enum { Right, Down, Left, Up };
fn Dir_to_string(dir: Dir) []const u8 {
    return switch (dir) {
        Dir.Right => "Right",
        Dir.Down => "Down",
        Dir.Left => "Left",
        Dir.Up => "Up",
    };
}

fn clean(field: *const Field, index: usize) void {
    if (field.data[index] == 1) {
        field.data[index] = 0;
        clean(field, index + 1);
        clean(field, index - 1);
        clean(field, index + field.width);
        clean(field, index - field.width);
    }
}
