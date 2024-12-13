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

fn solve(filename: []const u8) !void {
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

    // try print_machines(field);

    const result = try resolve(field);

    for (0..field.len) |i| {
        field[i].prize[0] += 10000000000000;
        field[i].prize[1] += 10000000000000;
    }

    const result2 = try resolve(field);

    const cout = std.io.getStdOut().writer();
    try cout.print("File: \"{s}\" Result: {d} | {d}\n", .{ filename, result, result2 });
}

pub fn main() anyerror!void {
    try solve("part1.example.txt");
    try solve("part1.test.txt");
}

const NumType = i64;
const Machine = struct {
    btnA: [2]NumType,
    btnB: [2]NumType,
    prize: [2]NumType,
};

fn create_field(txt: []const u8, alloc: *const std.mem.Allocator) ![]Machine {
    var iter = std.mem.split(u8, txt, "\n");
    var entry_count: usize = 0;
    var last_line_was_empty: bool = true;
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len > 1 and last_line_was_empty) {
            entry_count += 1;
        }
        last_line_was_empty = l.len <= 1;
    }

    var res = try alloc.alloc(Machine, entry_count);
    entry_count = 0;
    last_line_was_empty = true;
    iter.reset();
    while (iter.next()) |line| {
        const l = right_trim(line);
        if (l.len > 1) {
            if (last_line_was_empty) {
                entry_count += 1;
            }
            const pos = entry_count - 1;
            try parse_machine_attrib(l, &res[pos]);
        }
        last_line_was_empty = l.len <= 1;
    }
    return res;
}

fn parse_machine_attrib(line: []const u8, machine: *Machine) !void {
    var iter = std.mem.split(u8, line, " ");

    var x: NumType = 0;
    var y: NumType = 0;
    while (iter.next()) |set| {
        // const cout = std.io.getStdOut().writer();
        // try cout.print("Num: {s}\n", .{set});
        if (set[0] == 'X') {
            x = try std.fmt.parseInt(NumType, set[2 .. set.len - 1], 10);
        } else if (set[0] == 'Y') {
            y = try std.fmt.parseInt(NumType, set[2..], 10);
        }
    }

    iter.reset();
    var t = iter.next();
    const typ = t.?[0];
    if (typ == 'B') { // is Button
        t = iter.next();
        const a_or_b = t.?[0];
        if (a_or_b == 'A') {
            machine.btnA = .{ x, y };
        } else {
            machine.btnB = .{ x, y };
        }
    } else if (typ == 'P') { // is Prize
        machine.prize = .{ x, y };
    }
}

fn print_machines(machines: []const Machine) !void {
    const cout = std.io.getStdOut().writer();
    for (0..machines.len) |i| {
        const m = &machines[i];
        try cout.print("{d} A + {d} B = {d}\n", .{ m.btnA, m.btnB, m.prize });
    }
}

fn resolve(machines: []const Machine) !usize {
    var res: usize = 0;
    for (0..machines.len) |i| {
        const r = resolve_machine_2(&machines[i]);
        res += @intCast(r);
    }
    return res;
}

const price_for_a = 3;
const price_for_b = 1;

fn resolve_machine(m: *const Machine) NumType {
    var a: NumType = 0;
    var b: NumType = m.prize[0] / m.btnB[0];
    while (b >= 0) {
        const t = .{ a * m.btnA[0] + b * m.btnB[0], a * m.btnA[1] + b * m.btnB[1] };
        if (t[0] == m.prize[0]) {
            if (t[1] == m.prize[1]) {
                return price_for_a * a + price_for_b * b;
            } else if (t[1] < m.prize[1]) {
                a += 1;
            } else {
                const b2 = @subWithOverflow(b, 1);
                if (b2[1] == 1) {
                    break;
                }
                b = b2[0];
            }
        } else if (t[0] < m.prize[0]) {
            a += 1;
        } else {
            const b2 = @subWithOverflow(b, 1);
            if (b2[1] == 1) {
                break;
            }
            b = b2[0];
        }
    }
    return 0;
}

fn resolve_machine_2(m: *const Machine) NumType {
    const v1 = m.prize[0] * m.btnA[1] - m.prize[1] * m.btnA[0];
    const v2 = m.btnB[0] * m.btnA[1] - m.btnB[1] * m.btnA[0];
    if (@mod(v1, v2) != 0) {
        return 0;
    }
    const b = @divExact(v1, v2);
    if (b < 0) {
        return 0;
    }
    const v3 = m.prize[0] - m.btnB[0] * b;
    if (@mod(v3, m.btnA[0]) != 0) {
        return 0;
    }
    const a = @divExact(v3, m.btnA[0]);
    if (a < 0) {
        return 0;
    }
    return a * price_for_a + b * price_for_b;
}
