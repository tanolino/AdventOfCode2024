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

fn read_file(name: []const u8, alloc: *const std.mem.Allocator) ![]u8 {
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

    const data = try read_file(file, &alloc);
    const result = try solve(data, &alloc);

    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d}\n", .{ file, result });
}

pub fn main() !void {
    // try work_with_file("part1.example.txt");
    try work_with_file("part1.test.txt");
}

const Dir = enum { Up, Down, Left, Right };
const Field = struct { width: usize, height: usize, pos: usize, data: []u8, cmd: []Dir };

fn read_field(data: []const u8, alloc: *const Allocator) !Field {
    var iter = std.mem.split(u8, data, "\n");

    var field = Field{ .width = 0, .height = 0, .pos = 0, .cmd = undefined, .data = undefined };
    while (iter.next()) |line| {
        const l = trim(line);
        if (l.len <= 1) {
            break;
        }
        if (field.width == 0 or field.width > l.len) {
            field.width = l.len;
        }
        field.height += 1;
    }

    var cmds: usize = 0;
    while (iter.next()) |line| {
        const l = trim(line);
        if (l.len > 1) {
            cmds += l.len;
        }
    }

    field.data = try alloc.alloc(u8, field.width * field.height);
    field.cmd = try alloc.alloc(Dir, cmds);

    iter.reset();
    var height: usize = 0;
    while (iter.next()) |line| {
        const l = trim(line);
        if (l.len <= 1) {
            break;
        }
        for (0..field.width) |i| {
            var c = l[i];
            if (c == '@') {
                field.pos = i + height * field.width;
            }
            if (c != '#' and c != 'O') {
                c = '.';
            }
            field.data[height * field.width + i] = c;
        }
        height += 1;
    }

    cmds = 0;
    while (iter.next()) |line| {
        const l = trim(line);
        if (l.len < 1) {
            continue;
        }
        for (0..l.len) |i| {
            const c = l[i];
            if (switch (c) {
                '^' => Dir.Up,
                'v' => Dir.Down,
                '>' => Dir.Right,
                '<' => Dir.Left,
                else => null,
            }) |dir| {
                field.cmd[cmds] = dir;
                cmds += 1;
            }
        }
    }
    if (cmds < field.cmd.len) {
        field.cmd.len = cmds;
    }

    return field;
}

fn solve(data: []const u8, alloc: *const Allocator) ![2]usize {
    var field = try read_field(data, alloc);
    // print_field(&field);
    var field2 = try generate_field2(&field, alloc);
    simulate(&field);
    simulate2(&field2);
    return .{ count_value(&field), count_value(&field2) };
}

// Part 1

fn simulate(field: *Field) void {
    const w: i64 = @intCast(field.width);
    for (field.cmd) |d| {
        const offset: i64 = switch (d) {
            Dir.Up => -w,
            Dir.Down => w,
            Dir.Left => -1,
            Dir.Right => 1,
        };
        var pos: i64 = @intCast(field.pos);
        if (move_field(field, pos + offset, offset)) {
            pos += offset;
            field.pos = @intCast(pos);
        }
        // print_field(field);
    }
}

fn move_field(field: *const Field, pos: i64, offset: i64) bool {
    const c = field.data[@intCast(pos)];
    if (c == '#') {
        return false;
    } else if (c == '.') {
        return true;
    } else if (c == 'O') {
        const res = move_field(field, pos + offset, offset);
        if (res) {
            field.data[@intCast(pos + offset)] = 'O';
            field.data[@intCast(pos)] = '.'; // Not actually needed
        }
        return res;
    } else {
        // ????
        return false;
    }
}

fn print_field(field: *const Field) void {
    print("Field:", .{});
    for (0..field.data.len) |i| {
        if (@mod(i, field.width) == 0) {
            print("\n", .{});
        }
        if (i == field.pos) {
            print("@", .{});
        } else {
            print("{s}", .{field.data[i .. i + 1]});
        }
    }
    print("\n", .{});
}

fn count_value(field: *const Field) usize {
    var res: usize = 0;
    for (0..field.data.len) |i| {
        if (field.data[i] != 'O' and field.data[i] != '[') {
            continue;
        }
        const x = @mod(i, field.width);
        const y = @divFloor(i, field.width);
        res += 100 * y + x;
    }
    return res;
}

// Part 2

fn generate_field2(field: *const Field, alloc: *const Allocator) !Field {
    var res = Field{
        .cmd = field.cmd,
        .height = field.height,
        .width = field.width * 2,
        .pos = field.pos * 2,
        .data = undefined,
    };

    res.data = try alloc.alloc(u8, field.data.len * 2);
    var out = res.data;
    for (0..field.data.len) |i| {
        const c = field.data[i];
        switch (c) {
            '.' => {
                out[0] = '.';
                out[1] = '.';
            },
            'O' => {
                out[0] = '[';
                out[1] = ']';
            },
            else => {
                out[0] = '#';
                out[1] = '#';
            },
        }
        out = out[2..];
    }
    return res;
}

fn simulate2(field: *Field) void {
    // print_field(field);
    const w: i64 = @intCast(field.width);
    for (field.cmd) |d| {
        const offset: i64 = switch (d) {
            Dir.Up => -w,
            Dir.Down => w,
            Dir.Left => -1,
            Dir.Right => 1,
        };
        var pos: i64 = @intCast(field.pos);
        if (can_move(field, pos + offset, offset)) {
            move_field2(field, pos + offset, offset);
            pos += offset;
            field.pos = @intCast(pos);
        }
        // print_field(field);
    }
}

fn can_move(field: *const Field, pos: i64, offset: i64) bool {
    const c = field.data[@intCast(pos)];
    if (c == '[') {
        if (offset == 1) {
            return can_move(field, pos + 2, offset);
        } else if (offset == -1) {
            return can_move(field, pos - 1, offset);
        } else {
            return can_move(field, pos + offset, offset) and
                can_move(field, pos + offset + 1, offset);
        }
    } else if (c == ']') {
        if (offset == 1) {
            return can_move(field, pos + 1, offset);
        } else if (offset == -1) {
            return can_move(field, pos - 2, offset);
        } else {
            return can_move(field, pos + offset, offset) and
                can_move(field, pos + offset - 1, offset);
        }
    } else if (c == '.') {
        return true;
    } else { // '#'
        return false;
    }
}

fn move_field2(field: *Field, pos: i64, offset: i64) void {
    const c = field.data[@intCast(pos)];
    if (c == '[') {
        if (offset == 1) {
            move_field2(field, pos + 1, offset);
            field.data[@intCast(pos + 1)] = field.data[@intCast(pos)];
            field.data[@intCast(pos)] = '.';
        } else if (offset == -1) {
            move_field2(field, pos - 1, offset);
            field.data[@intCast(pos - 1)] = field.data[@intCast(pos)];
            field.data[@intCast(pos)] = '.';
        } else {
            move_field2(field, pos + offset, offset);
            field.data[@intCast(pos + offset)] = field.data[@intCast(pos)];
            field.data[@intCast(pos)] = '.';
            move_field2(field, pos + 1, offset);
        }
    } else if (c == ']') {
        if (offset == 1) {
            move_field2(field, pos + 1, offset);
            field.data[@intCast(pos + 1)] = field.data[@intCast(pos)];
            field.data[@intCast(pos)] = '.';
        } else if (offset == -1) {
            move_field2(field, pos - 1, offset);
            field.data[@intCast(pos - 1)] = field.data[@intCast(pos)];
            field.data[@intCast(pos)] = '.';
        } else {
            move_field2(field, pos + offset, offset);
            field.data[@intCast(pos + offset)] = field.data[@intCast(pos)];
            field.data[@intCast(pos)] = '.';
            move_field2(field, pos - 1, offset);
        }
    }
}
