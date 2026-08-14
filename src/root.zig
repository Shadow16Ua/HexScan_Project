const std = @import("std");
pub const State = struct {
    pub var gpa = std.heap.DebugAllocator(.{}).init;
    pub var threaded: std.Io.Threaded = undefined;
};

pub export fn init() void {
    State.threaded = std.Io.Threaded.init(State.gpa.allocator(), .{});
}
