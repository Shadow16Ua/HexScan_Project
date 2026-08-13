const std = @import("std");
pub const State = struct {
    pub var gpa = std.heap.DebugAllocator(.{}).init;
    pub var threaded: std.Io.Threaded = undefined;
};

pub export fn init() void {
    State.threaded = std.Io.Threaded.init(State.gpa.allocator(), .{});
}

pub export fn scan_file(path: [*:0]const u8) bool {
    const io = State.threaded.io();
    const file = std.Io.Dir.cwd().openFile(State.threaded.io(), std.mem.span(path), .{}) catch |err| {
        std.debug.panic("Failed to open file: {s}; Error is: {}", .{ path, err });
    };
    defer file.close(io);
    return true;
}
