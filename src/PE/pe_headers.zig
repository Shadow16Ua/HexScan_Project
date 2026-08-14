const std = @import("std");
const root = @import("global");
pub const types = root.types;
pub const PeInfo = types.PeInfo;

pub export fn parsePeFile(path: [*:0]const u8, out_info: *types.PeInfo) bool {
    const io = root.State.threaded.io();
    const allocator = root.State.gpa.allocator();
    const file = std.Io.Dir.cwd().openFile(io, std.mem.span(path), .{}) catch |err| {
        std.debug.print("Failed to open file: {s}; Error is: {}", .{ path, err });
        return false;
    };
    defer file.close(io);

    // 1. Зчитуємо DOS Header
    var dos_header: types.IMAGE_DOS_HEADER = undefined;
    const dos_bytes_read = file.readStreaming(io, &.{std.mem.asBytes(&dos_header)}) catch |err| {
        std.debug.print("Failed to read DOS header: {s}; Error is: {}", .{ path, err });
        return false;
    };
    if (dos_bytes_read < @sizeOf(types.IMAGE_DOS_HEADER)) return false;
    switch (dos_header.e_magic) {
        types.IMAGE_DOS_SIGNATURE => {},
        else => return false,
    }

    // 2. Переходимо до NT Headers за допомогою e_lfanew
    const nt_offset: u64 = @intCast(dos_header.e_lfanew);

    // Перевіряємо NT Signature ("types\0\0")
    var pe_signature: u32 = 0;
    _ = file.readPositionalAll(io, std.mem.asBytes(&pe_signature), nt_offset) catch |err| {
        std.debug.print("Failed to read NT signature: {s}; Error is: {}", .{ path, err });
        return false;
    };
    if (pe_signature != types.IMAGE_NT_SIGNATURE) return false;

    // 3. Зчитуємо File Header
    const file_header_offset = nt_offset + @sizeOf(u32);
    var file_header: types.IMAGE_FILE_HEADER = undefined;
    _ = file.readPositionalAll(io, std.mem.asBytes(&file_header), file_header_offset) catch |err| {
        std.debug.print("Failed to read file header: {s}; Error is: {}", .{ path, err });
        return false;
    };

    // 4. Зчитуємо Magic з Optional Header (щоб дізнатися 32 чи 64 біт)
    const opt_header_offset = file_header_offset + @sizeOf(types.IMAGE_FILE_HEADER);
    var opt_magic: u16 = 0;
    _ = file.readPositionalAll(io, std.mem.asBytes(&opt_magic), opt_header_offset) catch |err| {
        std.debug.print("Failed to read optional header magic: {s}; Error is: {}", .{ path, err });
        return false;
    };

    const is_64bit = (opt_magic == 0x20B); // 0x20B = PE32+, 0x10B = PE32

    // Зчитуємо EntryPoint (в залежності від 32/64 біт воно лежить за однаковим зміщенням +16 від початку Optional Header)
    var entry_point: u32 = 0;
    _ = file.readPositionalAll(io, std.mem.asBytes(&entry_point), opt_header_offset + 16) catch |err| {
        std.debug.print("Failed to read entry point: {s}; Error is: {}", .{ path, err });
        return false;
    };

    // 5. Зчитуємо секції (Section Headers)
    const section_headers_offset = opt_header_offset + file_header.SizeOfOptionalHeader;
    var sections = allocator.alloc(types.PeInfo.SectionInfo, file_header.NumberOfSections) catch |err| {
        std.debug.print("Failed to allocate memory for section headers: {s}; Error is: {}", .{ path, err });
        return false;
    };
    errdefer allocator.free(sections);

    var i: usize = 0;
    while (i < file_header.NumberOfSections) : (i += 1) {
        var sec_header: types.IMAGE_SECTION_HEADER = undefined;
        const current_sec_offset = section_headers_offset + (i * @sizeOf(types.IMAGE_SECTION_HEADER));

        _ = file.readPositionalAll(io, std.mem.asBytes(&sec_header), current_sec_offset) catch |err| {
            std.debug.print("Failed to read section header {d}: {s}; Error is: {}", .{ i, path, err });
            return false;
        };

        sections[i] = .{
            .name = sec_header.Name,
            .virtual_size = sec_header.VirtualSize,
            .raw_size = sec_header.SizeOfRawData,
            .characteristics = sec_header.Characteristics,
        };
    }

    out_info.* = types.PeInfo{
        .is_64bit = is_64bit,
        .number_of_sections = file_header.NumberOfSections,
        .entry_point = entry_point,
        .sections = sections.ptr,
        .type = .Unknown, // Placeholder for file type, can be determined based on characteristics if needed
    };
    return true;
}

pub export fn destroyPeInfo(pe_info: *types.PeInfo) void {
    const allocator = root.State.gpa.allocator();
    const sections = pe_info.sections[0..pe_info.number_of_sections];
    allocator.free(sections);
}
