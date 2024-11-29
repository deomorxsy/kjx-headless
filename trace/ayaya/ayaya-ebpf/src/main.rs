#![no_std]
#![no_main]

use aya_ebpf::{macros::tracepoint, programs::TracePointContext};
use aya_log_ebpf::info;

#[tracepoint]
pub fn ayaya(ctx: TracePointContext) -> u32 {
    match try_ayaya(ctx) {
        Ok(ret) => ret,
        Err(ret) => ret,
    }
}

fn try_ayaya(ctx: TracePointContext) -> Result<u32, u32> {
    info!(&ctx, "tracepoint sched_switch called");
    Ok(0)
}

#[cfg(not(test))]
#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}
