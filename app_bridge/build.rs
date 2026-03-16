fn main() {
    cxx_build::bridge("src/lib.rs")
        .flag_if_supported("-std=c++14")
        .compile("app_bridge_cxx");

    println!("cargo:rerun-if-changed=src/lib.rs");
}
