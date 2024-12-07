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

const Equation = struct {
    solution: usize,
    values: []usize,
};
fn free_equation(eq: *const Equation, alloc: *const std.mem.Allocator) void {
    alloc.free(eq.values);
}

const Task = struct {
    equations: []Equation,
};
fn free_task(task: *const Task, alloc: *const std.mem.Allocator) void {
    for (task.equations) |eq| {
        free_equation(&eq, alloc);
    }
    alloc.free(task.equations);
}

fn parse_Equation(text: []const u8, alloc: *const std.mem.Allocator) !Equation {
    var res: Equation = undefined;
    res.solution = 0;

    const t = right_trim(text);
    var num_count: usize = 0;
    var iter = std.mem.split(u8, t, " ");
    while (iter.next()) |num| {
        if (num[num.len - 1] != ':') {
            num_count += 1;
        }
    }
    res.values = try alloc.alloc(usize, num_count);

    num_count = 0;
    iter.reset();
    while (iter.next()) |num| {
        if (num[num.len - 1] != ':') {
            res.values[num_count] = try std.fmt.parseInt(usize, num, 10);
            num_count += 1;
        } else {
            res.solution = try std.fmt.parseInt(usize, num[0 .. num.len - 1], 10);
        }
    }
    return res;
}

fn parse_file_content(content: []const u8, alloc: *const std.mem.Allocator) !Task {
    var iter = std.mem.split(u8, content, "\n");
    var eq_count: usize = 0;
    while (iter.next()) |line| {
        if (line.len > 3) {
            eq_count += 1;
        }
    }

    var task = Task{ .equations = try alloc.alloc(Equation, eq_count) };
    iter.reset();
    eq_count = 0;
    while (iter.next()) |line| {
        if (line.len > 3) {
            task.equations[eq_count] = try parse_Equation(line, alloc);
            eq_count += 1;
        }
    }
    return task;
}

// Try to solve the eqation, return "it has a solution"
fn solve_recursive(target: usize, base: usize, vals: []usize) bool {
    if (base > target) {
        return false;
    } else if (vals.len == 0) {
        return base == target;
    } else {
        const slice = vals[1..];
        return solve_recursive(target, base + vals[0], slice) or
            solve_recursive(target, base * vals[0], slice);
    }
}

fn find_solution_part1(task: *const Task) usize {
    var res: usize = 0;
    for (task.equations) |eq| {
        if (solve_recursive(eq.solution, 0, eq.values)) {
            res += eq.solution;
        }
    }
    return res;
}

fn solve(filename: []const u8) !void {
    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const alloc = gp.allocator();

    const content = try read_all_file(filename, &alloc);
    defer alloc.free(content);

    const task = try parse_file_content(content, &alloc);
    defer free_task(&task, &alloc);

    const result1 = find_solution_part1(&task);
    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d}\n", .{ filename, result1 });
}

pub fn main() anyerror!void {
    try solve("part1.example.txt"); // p1: 3749
    try solve("part1.test.txt");
}
