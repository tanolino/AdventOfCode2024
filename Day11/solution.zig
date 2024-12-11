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

fn solve(filename: []const u8, count: usize) !void {
    //var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    //defer _ = gp.deinit();
    //const alloc = gp.allocator();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const content = try read_all_file(filename, &alloc);
    defer alloc.free(content);

    const field = try create_field(content, &alloc);
    defer alloc.free(field);

    var lookup = try alloc.alloc(std.AutoHashMap(usize, usize), count);
    for (0..lookup.len) |i| {
        lookup[i] = std.AutoHashMap(usize, usize).init(alloc);
    }
    defer {
        for (0..lookup.len) |i| {
            lookup[i].deinit();
        }
        alloc.free(lookup);
    }

    const result = try resolve(field, count, lookup);

    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Count: {d} Result: {d}\n", .{ filename, count, result });
}

pub fn main() anyerror!void {
    //try solve("part1.example.txt", 6); // 22
    //try solve("part1.example.txt", 25); // 55312
    try solve("part1.test.txt", 25); // 209412
    try solve("part1.test.txt", 75); // 248967696501656
}

fn create_field(content: []const u8, alloc: *const std.mem.Allocator) ![]usize {
    const trimmed = right_trim(content);
    var iter = std.mem.split(u8, trimmed, " ");
    var num_count: usize = 0;
    while (iter.next()) |txt| {
        const txt2 = right_trim(txt);
        if (txt2.len >= 1) {
            num_count += 1;
        }
    }

    var res: []usize = try alloc.alloc(usize, num_count);
    iter.reset();
    num_count = 0;
    while (iter.next()) |txt| {
        const txt2 = right_trim(txt);
        if (txt2.len >= 1) {
            res[num_count] = try std.fmt.parseInt(usize, txt2, 10);
            num_count += 1;
        }
    }
    return res;
}

fn resolve(field: []const usize, depth: usize, lookup: []std.AutoHashMap(usize, usize)) !usize {
    var res: usize = 0;
    for (0..field.len) |num| {
        res += try recursive_resolve(field[num], depth, lookup);
    }
    return res;
}

fn recursive_resolve(num: usize, depth: usize, lookup: []std.AutoHashMap(usize, usize)) !usize {
    if (depth <= 0) { // We have no more hoops
        return 1;
    } else if (num == 0) { // first rule
        return recursive_resolve(1, depth - 1, lookup);
    } else {
        const cache = lookup[depth - 1].get(num);
        if (cache == null) {
            const digits = count_digits(num);
            var res: usize = undefined;
            if (digits % 2 == 0) {
                const split = split_digit_at(num, digits / 2);
                res = try recursive_resolve(split[0], depth - 1, lookup);
                res += try recursive_resolve(split[1], depth - 1, lookup);
            } else {
                res = try recursive_resolve(2024 * num, depth - 1, lookup);
            }
            try lookup[depth - 1].put(num, res);
            return res;
        } else {
            return cache.?;
        }
    }
}

fn count_digits(num: usize) usize {
    var res: usize = 1;
    var n: usize = num;
    while (n >= 10) {
        n /= 10;
        res += 1;
    }
    return res;
}

fn split_digit_at(num: usize, pos: usize) [2]usize {
    var factor: usize = 10;
    for (1..pos) |_| {
        factor *= 10;
    }
    return .{ num / factor, num % factor };
}
