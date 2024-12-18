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

const Antenna = struct {
    x: usize,
    y: usize,
    c: u8,
};

const Field = struct {
    width: usize,
    height: usize,
    data: []u8, // Field of antinodes
    antennas: []Antenna,
};

fn free_field(field: *const Field, alloc: *const std.mem.Allocator) void {
    alloc.free(field.data);
    alloc.free(field.antennas);
}

fn clean_data(field: *Field) void {
    for (0..field.data.len) |i| {
        field.data[i] = '.';
    }
}

fn parse_file_content(content: []const u8, alloc: *const std.mem.Allocator) !Field {
    var iter = std.mem.split(u8, content, "\n");
    var line_count: usize = 0;
    var line_width: usize = 0;
    var antenna_count: usize = 0;
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len < 3) {
            continue;
        }

        for (l) |c| {
            if (c != '.') {
                antenna_count += 1;
            }
        }

        line_count += 1;
        if (line_width > 0) {
            line_width = @min(line_width, l.len);
        } else {
            line_width = l.len;
        }
    }

    var task = Field{ .width = line_width, .height = line_count, .data = undefined, .antennas = undefined };
    task.antennas = try alloc.alloc(Antenna, antenna_count);
    iter.reset();
    line_count = 0;
    antenna_count = 0;
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len < 3) {
            continue;
        }

        for (0..l.len) |c_i| {
            const c = l[c_i];
            if (c != '.') {
                task.antennas[antenna_count].c = c;
                task.antennas[antenna_count].x = c_i;
                task.antennas[antenna_count].y = line_count;
                antenna_count += 1;
            }
        }

        line_count += 1;
    }

    task.data = try alloc.alloc(u8, line_width * line_count);
    clean_data(&task);

    return task;
}

fn find_solution(field: *const Field, consider_resonance: bool) usize {
    if (consider_resonance) {
        for (field.antennas) |ant| {
            if (consider_resonance) {
                field.data[ant.x + ant.y * field.width] = '#';
            }
        }
    }
    for (0..field.antennas.len - 1) |pos1| {
        for (pos1 + 1..field.antennas.len) |pos2| {
            if (field.antennas[pos1].c != field.antennas[pos2].c) {
                continue;
            }

            const x1 = field.antennas[pos1].x;
            const y1 = field.antennas[pos1].y;
            const x2 = field.antennas[pos2].x;
            const y2 = field.antennas[pos2].y;

            var i: usize = 1;
            var xe = @subWithOverflow(x1 + x1, x2);
            var ye = @subWithOverflow(y1 + y1, y2);
            while (xe[1] == 0 and ye[1] == 0 and xe[0] < field.width and ye[0] < field.height) {
                field.data[xe[0] + field.width * ye[0]] = '#';

                if (!consider_resonance) {
                    break;
                }
                i += 1;
                xe = @subWithOverflow(x1 * (1 + i), x2 * i);
                ye = @subWithOverflow(y1 * (1 + i), y2 * i);
            }

            i = 1;
            xe = @subWithOverflow(x2 + x2, x1);
            ye = @subWithOverflow(y2 + y2, y1);
            while (xe[1] == 0 and ye[1] == 0 and xe[0] < field.width and ye[0] < field.height) {
                field.data[xe[0] + field.width * ye[0]] = '#';

                if (!consider_resonance) {
                    break;
                }
                i += 1;
                xe = @subWithOverflow(x2 * (1 + i), x1 * i);
                ye = @subWithOverflow(y2 * (1 + i), y1 * i);
            }
        }
    }

    var result: usize = 0;
    for (field.data) |c| {
        if (c == '#') {
            result += 1;
        }
    }
    return result;
}

fn solve(filename: []const u8) !void {
    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const alloc = gp.allocator();

    const content = try read_all_file(filename, &alloc);
    defer alloc.free(content);

    const field = try parse_file_content(content, &alloc);
    defer free_field(&field, &alloc);
    const result = find_solution(&field, false);
    const result2 = find_solution(&field, true);

    const cout = std.io.getStdOut().writer();
    const print_field = false;
    if (print_field) {
        try cout.print("Field:", .{});
        for (0..field.data.len) |i| {
            const x = i % field.width;
            if (x == 0) {
                try cout.print("\n", .{});
            }
            if (field.data[i] == '#') {
                try cout.print("# ", .{});
            } else {
                try cout.print(". ", .{});
            }
        }
        try cout.print("\n", .{});
    }
    try cout.print("File: \"{s}\" Result: {d} | {d}\n", .{ filename, result, result2 });
}

pub fn main() anyerror!void {
    // p1: 14
    // p2: 34
    // try solve("part1.example.txt");

    // p1: 305
    // p2: 1150
    try solve("part1.test.txt");
}
