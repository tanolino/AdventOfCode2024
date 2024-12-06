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

const Pos = [2]usize;
const Field = struct {
    size: Pos,
    data: []u8,
    start: Pos,
};
fn free_dataset(dataSet: *const Field, allocator: *const std.mem.Allocator) void {
    allocator.free(dataSet.data);
}

fn parse(content: []const u8, allocator: *const std.mem.Allocator) anyerror!Field {
    var field: Field = undefined;
    field.size = .{ 0, 0 };
    field.start = .{ 0, 0 }; // should not be neccessary

    // take measure
    var iter = std.mem.split(u8, content, "\n");
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len > 1) {
            if (l.len > field.size[0]) {
                field.size[0] = l.len;
            }
            field.size[1] += 1;
        }
    }

    // allocate and fill field
    field.data = try allocator.alloc(u8, field.size[0] * field.size[1]);
    for (0..field.data.len) |i| {
        field.data[i] = 0; // Zero all
    }

    iter.reset();
    var h: usize = 0;
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len > 1) {
            const offset = h * field.size[0];
            for (0..l.len) |w| {
                var c = l[w];
                if (c == '^') {
                    c = '.';
                    field.start = .{ w, h };
                }
                field.data[offset + w] = c;
            }
            h += 1;
        }
    }

    return field;
}

const Dir = enum { Up, Down, Left, Right };

const State = struct {
    pos: Pos,
    dir: Dir,
};

fn field_finished(field: *const Field, state: *const State) bool {
    // Check for out of field
    switch (state.dir) {
        Dir.Up => if (state.pos[1] == 0) {
            return true;
        },
        Dir.Down => if (state.pos[1] == field.size[1] - 1) {
            return true;
        },
        Dir.Left => if (state.pos[0] == 0) {
            return true;
        },
        Dir.Right => if (state.pos[0] == field.size[0] - 1) {
            return true;
        },
    }
    return false;
}

fn can_i_go_to(pos: Pos, field: *const Field) bool {
    return field.data[pos[1] * field.size[0] + pos[0]] != '#';
}

fn play_turn(field: *const Field, state: *State) void {
    const next_step = switch (state.dir) {
        Dir.Up => Pos{ state.pos[0], state.pos[1] - 1 },
        Dir.Down => Pos{ state.pos[0], state.pos[1] + 1 },
        Dir.Left => Pos{ state.pos[0] - 1, state.pos[1] },
        Dir.Right => Pos{ state.pos[0] + 1, state.pos[1] },
    };

    if (can_i_go_to(next_step, field)) {
        state.pos = next_step;
    } else {
        state.dir = switch (state.dir) {
            Dir.Up => Dir.Right,
            Dir.Right => Dir.Down,
            Dir.Down => Dir.Left,
            Dir.Left => Dir.Up,
        };
    }
}

fn find_solution(field: *Field) usize {
    var state = State{ .pos = field.start, .dir = Dir.Up };

    field.data[state.pos[1] * field.size[0] + state.pos[0]] = 'X';
    while (!field_finished(field, &state)) {
        play_turn(field, &state);
        field.data[state.pos[1] * field.size[0] + state.pos[0]] = 'X';
    }

    var result: usize = 0;
    for (0..field.data.len) |i| {
        if (field.data[i] == 'X') {
            result += 1;
        }
    }
    return result;
}

fn solve(filename: []const u8) !void {
    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const allocator = gp.allocator();

    const content = try read_all_file(filename, &allocator);
    defer allocator.free(content);

    var field = try parse(content, &allocator);
    defer free_dataset(&field, &allocator);

    const result = find_solution(&field);
    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d}\n", .{ filename, result });
}

pub fn main() anyerror!void {
    try solve("part1.example.txt");
    try solve("part1.test.txt");
}
