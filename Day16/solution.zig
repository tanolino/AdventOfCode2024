// Same procedure as every day

const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

fn trim_char(c: u8) bool {
    return switch (c) {
        '\n', '\t', ' ', '\r' => true,
        else => false,
    };
}

fn trim(txt: []const u8) []const u8 {
    var tmp = txt;
    while (tmp.len > 0 and trim_char(tmp[0])) {
        tmp = tmp[1..];
    }
    while (tmp.len > 0 and trim_char(tmp[tmp.len - 1])) {
        tmp = tmp[0 .. tmp.len - 1];
    }
    return tmp;
}

fn read_file(name: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(name, .{});
    const stat = try file.stat();
    var buffer = try alloc.alloc(u8, stat.size);
    const read_len = try file.readAll(buffer);
    if (read_len < buffer.len) {
        buffer.len = read_len;
    }
    return buffer;
}

fn work_with_file(file: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const data = try read_file(file, alloc);
    const result = try solve(data, alloc);

    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d}\n", .{ file, result });
}

pub fn main() !void {
    // try work_with_file("part1.example3.txt");
    //try work_with_file("part1.example.txt"); // 7036
    //try work_with_file("part1.example2.txt"); // 11048
    try work_with_file("part1.test.txt"); // 89460
}

fn solve(data: []const u8, alloc: Allocator) ![2]usize {
    var field = try build_field(data, alloc);
    const res = traverse_field(&field);
    const cache = try alloc.alloc(usize, field.size[0] * field.size[1]);
    const res2 = find_part_points(&field, cache);
    return .{ res, res2 };
}

const NumType = u32;
const WallValue = std.math.maxInt(NumType);
const UndefValue = WallValue - 1;
const Cell = [4]NumType;
const Field = struct { size: [2]usize = .{ 0, 0 }, start: usize = 0, end: usize = 0, data: []Cell };

fn build_field(data: []const u8, alloc: Allocator) !Field {
    var iter = std.mem.split(u8, data, "\n");
    var h: usize = 0;
    var w: usize = 0;
    while (iter.next()) |line| {
        const l = trim(line);
        if (l.len > 1) {
            if (w == 0 or w > l.len) {
                w = l.len;
            }
            h += 1;
        }
    }

    var field = Field{
        .size = .{ w, h },
        .data = try alloc.alloc(Cell, w * h),
    };

    iter.reset();
    h = 0;
    while (iter.next()) |line| {
        const l = trim(line);
        if (l.len <= 1) {
            continue;
        }
        for (0..w) |x| {
            const pos = x + h * field.size[0];
            if (l[x] == '#') {
                for (0..4) |r| {
                    field.data[pos][r] = WallValue;
                }
            } else {
                for (0..4) |r| {
                    field.data[pos][r] = UndefValue;
                }

                if (l[x] == 'S') {
                    field.start = pos;
                    field.data[pos][0] = 0;
                } else if (l[x] == 'E') {
                    field.end = pos;
                }
            }
        }
        h += 1;
    }

    return field;
}

fn traverse_field(field: *Field) usize {
    var something_done: bool = true;
    // print_field(field);
    while (something_done) {
        something_done = run_circle(field);
        something_done = run_north(field) or something_done;
        something_done = run_west(field) or something_done;
        something_done = run_east(field) or something_done;
        something_done = run_south(field) or something_done;
        // print_field(field);
        // break;
    }
    const e = field.end;
    return @min(field.data[e][0], field.data[e][1], field.data[e][2], field.data[e][3]);
}

fn print_field(field: *const Field, cache: []usize) void {
    print("Field:", .{});
    for (0..field.data.len) |i| {
        if (@mod(i, field.size[0]) == 0) {
            print("\n", .{});
        }
        if (field.data[i][0] == WallValue) {
            print("#", .{});
        } else if (i == field.end) {
            print("E", .{});
        } else if (@min(field.data[i][0], field.data[i][1], field.data[i][2], field.data[i][3]) < UndefValue) {
            var in_cache: bool = false;
            for (0..cache.len) |j| {
                if (cache[j] == i) {
                    in_cache = true;
                }
            }
            if (in_cache) {
                print("O", .{});
            } else {
                print("+", .{});
            }
        } else {
            print(".", .{});
        }
    }
    print("\n", .{});
}

// first slot
fn run_east(field: *Field) bool {
    var res: bool = false;
    for (1..field.data.len) |i| {
        const j = 0;

        const from = field.data[i - 1][j];
        const to = field.data[i][j];
        if (from >= UndefValue) {
            continue;
        } else if (to > UndefValue) {
            continue;
        } else if (from + 1 < to) {
            field.data[i][j] = from + 1;
            res = true;
        }
    }
    return res;
}

fn run_west(field: *Field) bool {
    var res: bool = false;
    for (2..field.data.len + 1) |i_1| {
        const i = field.data.len - i_1;
        const j = 2;

        const from = field.data[i + 1][j];
        const to = field.data[i][j];
        if (from >= UndefValue) {
            continue;
        } else if (to > UndefValue) {
            continue;
        } else if (from + 1 < to) {
            field.data[i][j] = from + 1;
            res = true;
        }
    }
    return res;
}

fn run_north(field: *Field) bool {
    var res: bool = false;
    for (field.size[0] + 1..field.data.len + 1) |i_1| {
        const i = field.data.len - i_1;
        const j = 1;

        const from = field.data[i + field.size[0]][j];
        const to = field.data[i][j];
        if (from >= UndefValue) {
            continue;
        } else if (to > UndefValue) {
            continue;
        } else if (from + 1 < to) {
            field.data[i][j] = from + 1;
            res = true;
        }
    }
    return res;
}

fn run_south(field: *Field) bool {
    var res: bool = false;
    for (field.size[0]..field.data.len) |i| {
        const j = 3;

        const from = field.data[i - field.size[0]][j];
        const to = field.data[i][j];
        if (from >= UndefValue) {
            continue;
        } else if (to > UndefValue) {
            continue;
        } else if (from + 1 < to) {
            field.data[i][j] = from + 1;
            res = true;
        }
    }
    return res;
}

fn run_circle(field: *Field) bool {
    var res: bool = false;
    for (0..field.data.len) |i| {
        for (0..4) |j| {
            const off3 = @mod(j + 1, 4);
            const from = field.data[i][j];
            const to = field.data[i][off3];
            if (from >= UndefValue) {
                continue;
            } else if (to > UndefValue) {
                continue;
            } else if (from + 1000 < to) {
                field.data[i][off3] = from + 1000;
                res = true;
            }
        }
        for (0..4) |j| {
            const off2 = @mod(j + 1, 4);
            const from = field.data[i][off2];
            const to = field.data[i][j];
            if (from >= UndefValue) {
                continue;
            } else if (to > UndefValue) {
                continue;
            } else if (from + 1000 < to) {
                field.data[i][j] = from + 1000;
                res = true;
            }
        }
    }
    return res;
}

// Part 2
fn find_part_points(field: *const Field, cache: []usize) usize {
    const e = field.end;
    cache[0] = e;
    for (1..cache.len) |i| {
        cache[i] = 0;
    }
    const min = @min(field.data[e][0], field.data[e][1], field.data[e][2], field.data[e][3]);
    for (0..4) |j| {
        if (min == field.data[field.end][j]) {
            find_part_points_ext(field, cache, field.end, j);
        }
    }

    var res: usize = 0;
    for (0..cache.len) |i| {
        if (cache[i] != 0) {
            res += 1;
        } else {
            break;
        }
    }
    // print_field(field, cache);
    return res;
}

fn find_part_points_ext(field: *const Field, cache: []usize, pos: usize, rotat: usize) void {
    for (0..cache.len) |i| {
        if (0 == cache[i]) {
            cache[i] = pos;
            break;
        } else if (pos == cache[i]) {
            break;
        }
    }

    if (pos == field.start) {
        return;
    }

    const current_val = field.data[pos][rotat];

    const rot_left = @mod(rotat + 3, 4);
    const rot_left_val = field.data[pos][rot_left];
    const rot_right = @mod(rotat + 1, 4);
    const rot_right_val = field.data[pos][rot_right];
    const straight_pos = switch (rotat) {
        0 => pos - 1,
        1 => pos + field.size[0],
        2 => pos + 1,
        else => pos - field.size[0],
    };
    const straight = field.data[straight_pos][rotat];

    if (false) {
        print("Min at {d} - ", .{pos});
        if (current_val - 1000 == rot_left_val) {
            print("left ", .{});
        }
        if (current_val - 1000 == rot_right_val) {
            print("right ", .{});
        }
        if (current_val - 1 == straight) {
            print("straight ", .{});
        }
        print("\n", .{});
    }

    if (current_val - 1000 == rot_left_val) {
        find_part_points_ext(field, cache, pos, rot_left);
    }
    if (current_val - 1000 == rot_right_val) {
        find_part_points_ext(field, cache, pos, rot_right);
    }
    if (current_val - 1 == straight) {
        find_part_points_ext(field, cache, straight_pos, rotat);
    }
}
