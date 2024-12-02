const std = @import("std");

pub fn right_trim(buff: []const u8) []const u8 {
    var tmp: []const u8 = buff[0..];
    while (tmp.len > 0 and (tmp[tmp.len - 1] == '\n' or tmp[tmp.len - 1] == '\r')) {
        tmp.len -= 1;
    }
    return tmp;
}

const State = enum { First, NoDir, Up, Down };
fn to_string(state: State) []const u8 {
    return switch (state) {
        State.First => "First",
        State.NoDir => "NoDir",
        State.Up => "Up",
        State.Down => "Down",
    };
}

pub fn test_numbers(nums: []const i64) bool {
    var state: State = State.First;
    var last_num: i64 = 0;
    for (nums) |num| {
        const diff = @abs(num - last_num);
        if (state == State.First) {
            state = State.NoDir;
        } else if (state == State.NoDir) {
            if (num < last_num) {
                state = State.Down;
            } else if (num > last_num) {
                state = State.Up;
            } else { // num == last_num
                return false;
            }

            if (diff > 3) {
                return false;
            }
        } else if (state == State.Down) {
            if (num >= last_num or diff > 3) {
                return false;
            }
        } else if (state == State.Up) {
            if (num <= last_num or diff > 3) {
                return false;
            }
        }
        last_num = num;
    }
    return true;
}

pub fn test_line_part1(line: []const u8) !bool {
    var nums = std.mem.zeroes([1024]i64);
    var pos: usize = 0;
    var splits = std.mem.split(u8, line, " ");
    while (splits.next()) |num_str| {
        if (num_str.len <= 0) {
            continue;
        }

        nums[pos] = try std.fmt.parseInt(i64, num_str, 10);
        pos += 1;
    }
    return test_numbers(nums[0..pos]);
}

pub fn test_line_part2(line: []const u8) !bool {
    var nums_buffer = std.mem.zeroes([1024]i64);
    var pos: usize = 0;
    var splits = std.mem.split(u8, line, " ");
    while (splits.next()) |num_str| {
        if (num_str.len <= 0) {
            continue;
        }

        nums_buffer[pos] = try std.fmt.parseInt(i64, num_str, 10);
        pos += 1;
    }
    const nums = nums_buffer[0..pos];
    if (test_numbers(nums)) {
        return true;
    }

    var nums_buffer2 = std.mem.zeroes([1024]i64);
    for (0..nums.len) |i| {
        for (0..nums.len - 1) |j| {
            var src = j;
            if (j >= i) {
                src += 1;
            }
            nums_buffer2[j] = nums[src];
        }
        if (test_numbers(nums_buffer2[0 .. nums.len - 1])) {
            return true;
        }
    }

    return false;
}

const Part = enum { P1, P2 };

pub fn read_input(filename: []const u8, part: Part) !usize {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const allocator = gp.allocator();

    const stat = try file.stat();
    var buffer = try allocator.alloc(u8, stat.size);
    defer allocator.free(buffer);
    const read_size = try file.readAll(buffer);
    if (read_size < buffer.len) {
        buffer.len = read_size;
    }
    var count: usize = 0;
    var splits = std.mem.split(u8, buffer, "\n");

    if (part == Part.P1) {
        while (splits.next()) |line| {
            const tmp = right_trim(line[0..]);
            if (tmp.len > 0 and try test_line_part1(tmp)) {
                count += 1;
            }
        }
    } else { // part == Part.p2
        while (splits.next()) |line| {
            const tmp = right_trim(line[0..]);
            if (tmp.len > 0 and try test_line_part2(tmp)) {
                count += 1;
            }
        }
    }
    return count;
}

pub fn solve_file(filename: []const u8) !void {
    const p1 = try read_input(filename, Part.P1);
    const p2 = try read_input(filename, Part.P2);

    const cout = std.io.getStdOut().writer();
    try cout.print("Input: \"{s}\" Part 1:{d} | Part 2:{d}\n", .{ filename, p1, p2 });
}

pub fn main() anyerror!void {
    try solve_file("part1.example.txt");
    try solve_file("part1.test.txt"); // 661 too low
}
