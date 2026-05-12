use std::path::Path;

use burn_onnx::ModelGen;

fn main() {
    ModelGen::new()
        .input("models/silero_vad_op18_ifless.onnx")
        .out_dir("models/")
        .run_from_script();

    let out = std::env::var("OUT_DIR").unwrap();
    let bpk = Path::new(&out).join("models/silero_vad_op18_ifless.bpk");
    std::fs::copy(&bpk, "models/silero_vad_op18_ifless.bpk").ok();
}
