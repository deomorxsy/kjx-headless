import { tryout } from "./cpu_trace.wasm";
import { tryout } from "./ram_trace.wasm";
import { tryout } from "./io_trace.wasm";
import { tryout } from "./net_trace.wasm";
import { tryout } from "./xdp_trace.wasm";
import { tryout } from "./lsm_trace.wasm";


const wasmInstance = await WebAssembly.instantiateStreaming(
    fetch(new URL("./add.wasm", import.meta.url)));

const { add } = wasmInstance.instance.exports as { add: (a: number, b: number) => number }

console.log(add(1, 2))


