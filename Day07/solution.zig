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
fn solve_recursive_par1(target: usize, base: usize, vals: []const usize) bool {
    if (base > target) {
        return false;
    } else if (vals.len == 0) {
        return base == target;
    } else {
        const slice = vals[1..];
        return solve_recursive_par1(target, base + vals[0], slice) or
            solve_recursive_par1(target, base * vals[0], slice);
    }
}

// Try to solve the eqation, return "it has a solution"
fn solve_recursive_par2(target: usize, base: usize, vals: []const usize) bool {
    if (base > target) {
        return false;
    } else if (vals.len == 0) {
        return base == target;
    } else {
        const slice = vals[1..];
        if (solve_recursive_par2(target, base + vals[0], slice)) {
            return true;
        } else if (solve_recursive_par2(target, base * vals[0], slice)) {
            return true;
        } else {
            // the new "||" operator
            var raise: usize = 1;
            var l: usize = vals[0];
            while (l >= 10) {
                raise *= 10;
                l /= 10;
            }
            raise *= 10;
            const new_base = base * raise + vals[0];
            return solve_recursive_par2(target, new_base, slice);
        }
    }
}

// Increased Complexity slows down by 40 to 50%
const Solved = enum { None, onlyP1, needP2 };
fn solve_recursive(target: usize, base: usize, vals: []const usize) Solved {
    if (base > target) {
        return Solved.None;
    } else if (vals.len == 0) {
        if (base == target) {
            return Solved.onlyP1;
        } else {
            return Solved.None;
        }
    } else {
        const slice = vals[1..];
        const solution1 = solve_recursive(target, base + vals[0], slice);
        const solution2 = solve_recursive(target, base * vals[0], slice);
        if (solution1 == Solved.onlyP1 or solution2 == Solved.onlyP1) {
            return Solved.onlyP1;
        } else if (solution1 == Solved.needP2 or solution2 == Solved.needP2) {
            return Solved.needP2;
        } else {
            // the new "||" operator
            const l: f64 = @floatFromInt(vals[0]);
            const l2: usize = @intFromFloat(@log10(l));
            var raise: usize = 1;
            for (0..l2 + 1) |_| {
                raise *= 10;
            }
            const new_base = base * raise + vals[0];
            if (solve_recursive(target, new_base, slice) != Solved.None) {
                return Solved.needP2;
            } else {
                return Solved.None;
            }
        }
    }
}

fn find_solution(task: *const Task) [2]usize {
    var res: [2]usize = .{ 0, 0 };
    for (task.equations) |eq| {
        if (solve_recursive_par1(eq.solution, 0, eq.values)) {
            res[0] += eq.solution;
            res[1] += eq.solution;
        } else if (solve_recursive_par2(eq.solution, 0, eq.values)) {
            res[1] += eq.solution;
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

    const result = find_solution(&task);
    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d} | {d}\n", .{ filename, result[0], result[1] });
}

pub fn main() anyerror!void {
    // p1: 3749
    // p2: 11387
    // try solve("part1.example.txt");

    // p1: 1611660863222
    // p2: 945341732469724
    try solve("part1.test.txt");
}
