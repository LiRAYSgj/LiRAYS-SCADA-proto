#![forbid(unsafe_code)]

pub mod namespace {
    pub mod v1 {
        include!(concat!(env!("OUT_DIR"), "/namespace.v1.rs"));
    }
}
