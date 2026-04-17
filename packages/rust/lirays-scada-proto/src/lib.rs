#![forbid(unsafe_code)]

pub mod namespace {
    include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/generated/namespace.rs"));
}
