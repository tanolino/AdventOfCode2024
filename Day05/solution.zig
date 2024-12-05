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

const Rule = [2]usize;
const PageSet = []usize;

const DataSet = struct {
    rules: []Rule,
    page_sets: []PageSet,
};

fn free_dataset(dataSet: *const DataSet, allocator: *const std.mem.Allocator) void {
    allocator.free(dataSet.rules);

    for (dataSet.page_sets) |p| {
        allocator.free(p);
    }
    allocator.free(dataSet.page_sets);
}

fn parse_rule(txt: []const u8, rule: *Rule) !void {
    var it2 = std.mem.split(u8, txt, "|");
    var num: ?[]const u8 = it2.next();
    if (num != null) {
        rule[0] =
            try std.fmt.parseInt(usize, num.?, 10);
    } else {
        rule[0] = 0;
    }
    num = it2.next();
    if (num != null) {
        rule[1] =
            try std.fmt.parseInt(usize, num.?, 10);
    } else {
        rule[1] = 0;
    }
}

fn parse_page_sets(txt: []const u8, allocator: *const std.mem.Allocator) !PageSet {
    var it2 = std.mem.split(u8, txt, ",");
    var pos: usize = 0;
    while (it2.next()) |_| {
        pos += 1;
    }
    var page_set = try allocator.alloc(usize, pos);
    it2.reset();
    pos = 0;
    while (it2.next()) |number| {
        page_set[pos] = try std.fmt.parseInt(usize, number, 10);
        pos += 1;
    }
    return page_set;
}

fn parse(txt: []const u8, allocator: *const std.mem.Allocator) !DataSet {
    var split_iter = std.mem.split(u8, txt, "\n");

    var count_rules: usize = 0;
    while (split_iter.next()) |line| {
        const l = right_trim(line);
        if (l.len <= 0) {
            break;
        } else {
            count_rules += 1;
        }
    }

    var count_page_sets: usize = 0;
    while (split_iter.next()) |line| {
        const l = right_trim(line);
        if (l.len <= 0) {
            break;
        } else {
            count_page_sets += 1;
        }
    }

    var res = DataSet{
        .rules = try allocator.alloc(Rule, count_rules),
        .page_sets = try allocator.alloc(PageSet, count_page_sets),
    };

    split_iter.reset();
    count_rules = 0;
    while (split_iter.next()) |line| {
        const l = right_trim(line);
        if (l.len <= 0) {
            break;
        } else {
            try parse_rule(l, &res.rules[count_rules]);
            count_rules += 1;
        }
    }

    count_page_sets = 0;
    while (split_iter.next()) |line| {
        const l = right_trim(line);
        if (l.len <= 0) {
            break;
        } else {
            res.page_sets[count_page_sets] = try parse_page_sets(l, allocator);
            count_page_sets += 1;
        }
    }

    return res;
}

fn is_against_rules(numA: usize, numB: usize, rules: []const Rule) bool {
    for (rules) |r| {
        if (numA == r[0] and numB == r[1]) {
            return false;
        } else if (numA == r[1] and numB == r[0]) {
            return true;
        }
    }
    return false; // probably ... ?
}

fn is_page_ok(page: PageSet, rules: []const Rule) bool {
    for (0..page.len - 1) |s| {
        for (s..page.len) |e| {
            if (is_against_rules(page[s], page[e], rules)) {
                return false;
            }
        }
    }
    return true;
}

fn find_correctly_ordered_page_sets(data: *const DataSet) !usize {
    var res: usize = 0;
    const cout = std.io.getStdOut().writer();
    for (data.page_sets) |page_set| {
        if (is_page_ok(page_set, data.rules)) {
            try cout.print("\tpages: ", .{});
            const highlight_cell = page_set.len / 2;
            for (0..page_set.len) |n| {
                if (highlight_cell == n) {
                    try cout.print(" [{d}]", .{page_set[n]});
                    res += page_set[n];
                } else {
                    try cout.print(" {d}", .{page_set[n]});
                }
            }
            try cout.print("\n", .{});
        }
    }
    return res;
}

fn solve(filename: []const u8) !void {
    var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gp.deinit();
    const allocator = gp.allocator();

    const content = try read_all_file(filename, &allocator);
    defer allocator.free(content);

    const dataSet = try parse(content, &allocator);
    defer free_dataset(&dataSet, &allocator);

    const cout = std.io.getStdOut().writer();
    const result = try find_correctly_ordered_page_sets(&dataSet);
    try cout.print("File: \"{s}\" Result: {d}", .{ filename, result });

    if (false) {
        for (dataSet.rules) |r| {
            try cout.print("\trule: {d} {d}\n", .{ r[0], r[1] });
        }
        for (dataSet.page_sets) |s| {
            try cout.print("\tpages: ", .{});
            for (s) |n| {
                try cout.print(" {d}", .{n});
            }
            try cout.print("\n", .{});
        }
    }
}

pub fn main() anyerror!void {
    try solve("part1.example.txt");
    try solve("part1.test.txt");
}
