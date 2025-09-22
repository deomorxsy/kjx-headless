//const std = @import("std");
//

const vmlinux = @import("./vmlinux");
// const vmlinux = @import("vmlinux");

// the category of tracepoint is found at tracefs/events/
category: []const u8,

// the name of tracepoint is found at tracefs/events/category-name
name: []const u8,

const Self = @This();

// gets ELF section name of the tracepoint used by libbpf
pub fn section(comptime self: Self) []const u8 {
    return "tracepoint" ++ self.category ++ "/" ++ self.name;
}

pub fn Ctx(comptime self: Self) type {
    const struct_name = "trace_event_raw_" ++ self.name;
    return @field(vmlinux, struct_name);
}
