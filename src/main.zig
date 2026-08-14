const std = @import("std");
const root = @import("root.zig");
const pe = @import("pe_headers.zig");

pub export fn scan_file(path: [*:0]const u8) bool {
    const io = root.State.threaded.io();
    const file = std.Io.Dir.cwd().openFile(root.State.threaded.io(), std.mem.span(path), .{}) catch |err| {
        std.debug.panic("Failed to open file: {s}; Error is: {}", .{ path, err });
        return false;
    };
    var sha256 = std.crypto.hash.sha2.Sha256.init(.{});
    var buf: [8192]u8 = undefined;
    while (true) {
        const read = file.readStreaming(io, &.{buf[0..]}) catch |err| {
            if (err == std.Io.Reader.Error.EndOfStream) break;
            std.debug.panic("Failed to read file: {s}; Error is: {}", .{ path, err });
            return false;
        };
        if (read == 0) break;
        sha256.update(buf[0..read]);
    }

    const hash = sha256.finalResult();
    std.debug.print("SHA-256 hash of {s}: {any}\n", .{ path, hash });
    defer file.close(io);
    return true;
}

pub const PeInfo = pe.PeInfo;
pub const parsePeFile = pe.parsePeFile;
pub const destroyPeInfo = pe.destroyPeInfo;
