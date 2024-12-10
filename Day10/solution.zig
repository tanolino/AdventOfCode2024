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
    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const alloc = gp.allocator();

    const content = try read_all_file(filename, &alloc);
    defer alloc.free(content);
    const field = try create_field(content, &alloc);
    defer alloc.free(field.data);

    var map = Field{
        .width = field.width,
        .height = field.height,
        .data = try alloc.alloc(u8, field.data.len),
    };
    defer alloc.free(map.data);
    for (0..map.data.len) |i| {
        map.data[i] = '.';
    }

    const result = resolve(&field, &map);

    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d}\n", .{ filename, result });
}

pub fn main() anyerror!void {
    // p1: 36
    // p2:
    try solve("part1.example.txt");

    // p1: 587
    // p2:
    try solve("part1.test.txt");
}

const Field = struct {
    width: usize,
    height: usize,
    data: []u8,
};

fn create_field(content: []const u8, alloc: *const std.mem.Allocator) !Field {
    var line_count: usize = 0;
    var line_width: usize = 0;
    var iter = std.mem.split(u8, content, "\n");
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len <= 1) {
            continue;
        }
        line_count += 1;
        line_width = l.len;
    }

    var field: Field = undefined;
    field.width = line_width;
    field.height = line_count;
    field.data = try alloc.alloc(u8, field.width * field.height);

    iter.reset();
    line_count = 0;
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len <= 1) {
            continue;
        }
        const start = line_count * field.width;
        const end = (line_count + 1) * field.width;
        const dst = field.data[start..end];
        std.mem.copyForwards(u8, dst, l[0..field.width]);
        line_count += 1;
    }
    return field;
}

fn print_content(field: *const Field) !void {
    const cout = std.io.getStdOut().writer();
    for (0..field.height) |h| {
        const offset = h * field.width;
        const end = (h + 1) * field.width;
        try cout.print("{s}\n", .{field.data[offset..end]});
    }
    try cout.print("\n", .{});
}

fn resolve(field: *const Field, map: *Field) [2]usize {
    var p1: usize = 0;
    var p2: usize = 0;
    for (0..field.data.len) |i| {
        if (field.data[i] == '0') {
            p2 += get_value_trailhead(field, map, i % field.width, i / field.width);

            var score_trailhead: usize = 0;
            for (0..map.data.len) |j| {
                if (map.data[j] == '9') {
                    score_trailhead += 1;
                }
                map.data[j] = '.';
            }
            // const cout = std.io.getStdOut().writer();
            // try cout.print("Score Trailhead: {d}\n", .{score_trailhead});
            p1 += score_trailhead;
        }
    }
    return .{ p1, p2 };
}

fn get_value_trailhead(field: *const Field, map: *Field, x: usize, y: usize) usize {
    const pos = y * field.width + x;
    const num = field.data[pos];
    map.data[pos] = num;
    if (num != '9') {
        var p2: usize = 0;
        const next = num + 1;
        if (y + 1 < field.height and field.data[(y + 1) * field.width + x] == next) {
            p2 += get_value_trailhead(field, map, x, y + 1);
        }
        if (y > 0 and field.data[(y - 1) * field.width + x] == next) {
            p2 += get_value_trailhead(field, map, x, y - 1);
        }
        if (x + 1 < field.width and field.data[y * field.width + x + 1] == next) {
            p2 += get_value_trailhead(field, map, x + 1, y);
        }
        if (x > 0 and field.data[y * field.width + x - 1] == next) {
            p2 += get_value_trailhead(field, map, x - 1, y);
        }
        return p2;
    } else {
        return 1;
    }
}
