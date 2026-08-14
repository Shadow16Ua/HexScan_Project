const std = @import("std");
pub const types = @import("PE/pe_types.zig");
pub const State = struct {
    pub var gpa = std.heap.DebugAllocator(.{}).init;
    pub var threaded: std.Io.Threaded = undefined;
};

pub export fn init() void {
    State.threaded = std.Io.Threaded.init(State.gpa.allocator(), .{});
}
pub export fn deinit() void {
    State.threaded.deinit();
    std.debug.assert(State.gpa.deinit() == .ok);
}

pub const FileInfo = extern struct {
    size: usize,
    rwe: c_char, // Readable, Writable, Executable mode
    PeInfo: types.PeInfo,
    hashes: [*][std.crypto.hash.sha2.Sha256.digest_length]u8, // Array of hashes SHA-256
    number_of_hashes: usize, // Number of hashes in the array
};
