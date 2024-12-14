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

fn solve(filename: []const u8, width: usize, height: usize) !void {
    //var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    //defer _ = gp.deinit();
    //const alloc = gp.allocator();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const content = try read_all_file(filename, &alloc);
    defer alloc.free(content);

    const robots = try read_robots(content, &alloc);
    defer alloc.free(robots);

    const result = resolve(robots, width, height);

    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d}\n", .{ filename, result });
}

pub fn main() anyerror!void {
    // try solve("part1.example.11x7.txt", 11, 7); // 12
    try solve("part1.test.101x103.txt", 101, 103); // 228410028
}

const Robot = struct {
    pos: [2]i64,
    dir: [2]i64,
};

fn read_robots(data: []const u8, alloc: *const std.mem.Allocator) ![]Robot {
    var iter = std.mem.split(u8, data, "\n");
    var line_count: usize = 0;
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len > 1) {
            line_count += 1;
        }
    }

    var res = try alloc.alloc(Robot, line_count);
    line_count = 0;
    iter.reset();
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len > 1) {
            try read_one_robot(l, &res[line_count]);
            line_count += 1;
        }
    }
    return res;
}

fn read_one_robot(line: []const u8, rob: *Robot) !void {
    var iter = std.mem.split(u8, line, " ");
    const pos = iter.next();
    rob.pos = try read_number_pair(pos.?[2..]);
    const dir = iter.next();
    rob.dir = try read_number_pair(dir.?[2..]);
}

fn read_number_pair(pair: []const u8) ![2]i64 {
    var iter = std.mem.split(u8, pair, ",");
    const num = try std.fmt.parseInt(i64, iter.next().?, 10);
    const num2 = try std.fmt.parseInt(i64, iter.next().?, 10);
    return .{ num, num2 };
}

fn resolve(robs: []const Robot, width: usize, height: usize) usize {
    const w: i64 = @intCast(width);
    const h: i64 = @intCast(height);
    const w_h = @divExact(w - 1, 2);
    const h_h = @divExact(h - 1, 2);
    var quad: [4]usize = .{ 0, 0, 0, 0 };

    //const cout = std.io.getStdOut().writer();
    for (0..robs.len) |i| {
        const rob: *const Robot = &robs[i];
        const factor = 100;
        var end_x = rob.pos[0] + rob.dir[0] * factor;
        var end_y = rob.pos[1] + rob.dir[1] * factor;
        // while (end_x < 0) { end_x += w; }
        end_x = @mod(end_x, w);

        // while (end_y < 0) { end_y += h; }
        end_y = @mod(end_y, h);

        //try cout.print("{d} + 100 {d} = {d} | {d}\n", .{ rob.pos, rob.dir, end_x, end_y });

        if (end_x == w_h or end_y == h_h) {
            continue;
        }
        var quad_id: usize = 0;
        if (end_x > w_h) {
            quad_id += 1;
        }
        if (end_y > h_h) {
            quad_id += 2;
        }
        quad[quad_id] += 1;
    }
    //try cout.print("\n", .{});
    return quad[0] * quad[1] * quad[2] * quad[3];
}
