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

fn exp2(num: usize) usize {
    var res: usize = 1;
    for (0..num) |_| {
        res *= 2;
    }
    return res;
}

fn work_with_file(file: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const data = try read_file(file, alloc);
    var state = try build_pc(data, alloc);
    var orig: State = undefined;
    set_pc(&orig, &state);

    solve(&state);
    const cout = std.io.getStdOut().writer();
    try cout.print("Part 1 Output: ", .{});
    for (0..state.out_count) |i| {
        if (i != 0) {
            try cout.print(",", .{});
        }
        try cout.print("{d}", .{state.out[i]});
    }
    try cout.print("\n", .{});

    // Part 2 is more hacky
    // We get 1 more output every 2^(3x) numbers
    // the first number changes almost every time,
    // the second number changes almost every 2^3
    // the third every 2^6
    // ...
    // So to even reach a number of height state.programm.len,
    // we need 2^(3 * state.programm.len - 1)
    var missmatch_pos: ?usize = state.programm.len;
    var num: usize = 0;
    var attempts: usize = 0;
    while (missmatch_pos != null) {
        set_pc(&state, &orig);
        state.RegA = @intCast(num);
        solve(&state);

        missmatch_pos = null;
        for (0..state.programm.len) |i| {
            const j: usize = state.programm.len - (i + 1);
            if (state.out_count < j or state.programm[j] != state.out[j]) {
                missmatch_pos = j;
                attempts += 1;
                break;
            }
        }

        if (missmatch_pos) |pos| {
            num += change(pos);
        }
    }
    //for (0..state.out_count) |k| {
    //    try cout.print("{d}", .{state.out[k]});
    //}
    //try cout.print(" - RegA: {d} - Attempts: {d}\n", .{ num, attempts });
    try cout.print("Part 2: {d} - Attempts: {d}\n", .{ num, attempts });
}

pub fn change(pos: usize) usize {
    const number = exp2(3 * pos);
    return number;
}

pub fn main() !void {
    // try work_with_file("part1.example.txt");
    // try work_with_file("part2.example.txt");
    try work_with_file("part1.test.txt");
}

const NumType = u64;
const CmdType = u3;
const State = struct {
    RegA: NumType = 0,
    RegB: NumType = 0,
    RegC: NumType = 0,
    CmdPtr: usize = 0,
    programm: []CmdType,
    firstOut: bool = true,
    out: []NumType,
    out_count: usize = 0,
};

fn set_pc(dst: *State, src: *const State) void {
    dst.RegA = src.RegA;
    dst.RegB = src.RegB;
    dst.RegC = src.RegC;
    dst.CmdPtr = src.CmdPtr;
    dst.programm = src.programm;
    dst.firstOut = src.firstOut;
    dst.out = src.out;
    dst.out_count = src.out_count;
}

fn build_pc(text: []const u8, alloc: Allocator) !State {
    var state = State{ .programm = undefined, .out = try alloc.alloc(NumType, 1000) };
    var iter = std.mem.split(u8, text, "\n");
    while (iter.next()) |line| {
        const l = trim(line);
        if (l.len == 0) {
            break;
        }
        var iter2 = std.mem.split(u8, l, " ");
        _ = iter2.next();
        const c = iter2.next().?[0];
        const num_str = iter2.next().?;

        const num = try std.fmt.parseInt(NumType, num_str, 10);
        switch (c) {
            'A' => {
                state.RegA = num;
            },
            'B' => {
                state.RegB = num;
            },
            'C' => {
                state.RegC = num;
            },
            else => {
                print("Unknown Register {s}", .{l[10..11]});
            },
        }
    }

    if (iter.next()) |programmLine| {
        const l = trim(programmLine);
        var iter2 = std.mem.split(u8, l, " ");
        _ = iter2.next();
        const cmd_txt = iter2.next().?;

        var cmd_count: usize = 0;
        var iter3 = std.mem.split(u8, cmd_txt, ",");
        while (iter3.next()) |_| {
            cmd_count += 1;
        }
        state.programm = try alloc.alloc(CmdType, cmd_count);
        cmd_count = 0;
        iter3.reset();
        while (iter3.next()) |c| {
            state.programm[cmd_count] = try std.fmt.parseInt(CmdType, c, 10);
            cmd_count += 1;
        }
    }
    return state;
}

fn print_pc(state: *const State) void {
    print("Reg A: {d}\n", .{state.RegA});
    print("Reg B: {d}\n", .{state.RegB});
    print("Reg C: {d}\n\n", .{state.RegC});
    print("Program: ", .{});
    for (0..state.programm.len) |i| {
        if (i == state.CmdPtr) {
            print("[", .{});
        }
        print("{d}", .{state.programm[i]});
        if (i == state.CmdPtr + 1) {
            print("]", .{});
        }
        if (i != state.programm.len - 1) {
            print(",", .{});
        }
    }
    print("\n", .{});
}

fn solve(state: *State) void {
    while (state.CmdPtr + 1 < state.programm.len) {
        const cmd = state.programm[state.CmdPtr];
        state.CmdPtr += 1;
        const cmb_op = state.programm[state.CmdPtr];
        state.CmdPtr += 1;

        execute_cmd(state, cmd, cmb_op);
    }
}

fn execute_cmd(state: *State, cmd: CmdType, cmb_op: CmdType) void {
    const cmd_op_val: NumType = switch (cmb_op) {
        0, 1, 2, 3 => @intCast(cmb_op),
        4 => state.RegA,
        5 => state.RegB,
        6 => state.RegC,
        7 => 0,
    };
    switch (cmd) {
        0 => {
            var denom: NumType = 1;
            for (0..cmd_op_val) |_| {
                denom *= 2;
            }
            // state.RegA = @divTrunc(state.RegA, denom);
            state.RegA = @divFloor(state.RegA, denom);
        },
        1 => {
            state.RegB = state.RegB ^ cmd_op_val;
        },
        2 => {
            state.RegB = @mod(cmd_op_val, 8);
        },
        3 => {
            if (state.RegA != 0) {
                state.CmdPtr = cmd_op_val;
            }
        },
        4 => {
            state.RegB = state.RegB ^ state.RegC;
        },
        5 => {
            const new_out = @mod(cmd_op_val, 8);
            state.out[state.out_count] = new_out;
            state.out_count += 1;
        },
        6 => {
            var denom: NumType = 1;
            for (0..cmd_op_val) |_| {
                denom *= 2;
            }
            state.RegB = @divTrunc(state.RegA, denom);
        },
        7 => {
            var denom: NumType = 1;
            for (0..cmd_op_val) |_| {
                denom *= 2;
            }
            state.RegC = @divTrunc(state.RegA, denom);
        },
    }
}
