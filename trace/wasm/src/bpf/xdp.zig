pub const RET = enum(c_int) {
    // xdp return action
    aborted, // for program errors
    drop, // for dropping current packet
    pass, // pass current packet again to the origin NIC, pattern: modify payload before
    tx, // bounce packet to same nic it arrived
    redirect,
};

// XDP context
pub const Meta = extern struct {
    data_begin: u32,
    data_end: u32,
    data_meta: u32,
    ingress_ifindex: u32,
    rx_queue_index: u32,
    egress_ifindex: u32,


    pub fn get_ptr(self: *Meta, comptime T: type, offset: usize) ?*T {
        const ptr: usize = self.data_begin + offset;

        if (ptr + @sizeOf(T) > self.data_end) return null;

        return @ptrFromInt(ptr);
    }
};
