const std = @import("std");
const root = @import("global");
const pe = @import("PE/pe_headers.zig");

pub export fn scan_file(path: [*:0]const u8, out_info: *root.FileInfo) bool {
    const io = root.State.threaded.io();
    const file = std.Io.Dir.cwd().openFile(root.State.threaded.io(), std.mem.span(path), .{}) catch |err| {
        std.debug.print("Failed to open file: {s}; Error is: {}", .{ path, err });
        return false;
    };
    defer file.close(io);
    var sha256 = std.crypto.hash.sha2.Sha256.init(.{});
    var buf: [8192]u8 = undefined;
    while (true) {
        const read = file.readStreaming(io, &.{buf[0..]}) catch |err| {
            if (err == std.Io.Reader.Error.EndOfStream) break;
            std.debug.print("Failed to read file: {s}; Error is: {}", .{ path, err });
            return false;
        };
        if (read == 0) break;
        sha256.update(buf[0..read]);
    }

    const hash = sha256.finalResult();
    std.debug.print("SHA-256 hash of {s}: {any}\n", .{ path, hash });
    const stats = file.stat(io) catch |err| {
        std.debug.print("Failed to stat file: {s}; Error is: {}", .{ path, err });
        return false;
    };
    var pe_info: PeInfo = undefined;
    if (!pe.parsePeFile(path, &pe_info)) return false;
    const allocator = root.State.gpa.allocator();
    const hashes = allocator.alloc([hash.len]u8, 1) catch |err| {
        std.debug.print("Failed to allocate memory for hash: {s}; Error is: {}", .{ path, err });
        return false;
    };
    const hash_one = &hashes[0];
    @memcpy(hash_one, hash[0..]);
    out_info.* = .{
        .size = stats.size,
        .hashes = hashes.ptr,
        .number_of_hashes = 1,
        .rwe = 0, // Placeholder for RWE mode
        .PeInfo = pe_info,
    };
    return true;
}
pub export fn destroy_file_info(info: *root.FileInfo) void {
    const allocator = root.State.gpa.allocator();
    allocator.free(info.hashes[0..info.number_of_hashes]);
    pe.destroyPeInfo(&info.PeInfo);
}

pub const PeInfo = pe.PeInfo;
pub const parsePeFile = pe.parsePeFile;
pub const destroyPeInfo = pe.destroyPeInfo;
