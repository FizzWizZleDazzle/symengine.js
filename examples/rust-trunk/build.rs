use std::env;
use std::path::PathBuf;

fn main() {
    // Determine library search path.
    // Priority: SYMENGINE_LIB_DIR env > relative path from project root.
    let lib_dir = if let Ok(dir) = env::var("SYMENGINE_LIB_DIR") {
        PathBuf::from(dir)
    } else {
        // Default: assume the repo was built with `./build_wasm.sh --arch=unknown`
        let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
        manifest.join("../../dist/wasm-unknown/lib")
    };

    println!("cargo:rustc-link-search=native={}", lib_dir.display());
    println!("cargo:rustc-link-lib=static=symengine");

    // If built with GMP, also link libgmp
    let gmp_lib = lib_dir.join("libgmp.a");
    if gmp_lib.exists() {
        println!("cargo:rustc-link-lib=static=gmp");
    }

    // Re-run if the library changes
    println!("cargo:rerun-if-env-changed=SYMENGINE_LIB_DIR");
    println!(
        "cargo:rerun-if-changed={}",
        lib_dir.join("libsymengine.a").display()
    );
}
