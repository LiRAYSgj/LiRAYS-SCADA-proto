use std::error::Error;
use std::ffi::OsStr;
use std::path::{Path, PathBuf};

fn collect_proto_files(proto_root: &Path) -> Vec<PathBuf> {
    let mut files = Vec::new();
    for entry in walkdir::WalkDir::new(proto_root)
        .into_iter()
        .filter_map(Result::ok)
        .filter(|entry| entry.file_type().is_file())
    {
        if entry.path().extension() == Some(OsStr::new("proto")) {
            files.push(entry.path().to_path_buf());
        }
    }
    files.sort();
    files
}

fn resolve_proto_root(manifest_dir: &Path) -> Result<PathBuf, Box<dyn Error>> {
    let vendored_proto_dir = manifest_dir.join("proto");
    if vendored_proto_dir.exists() {
        return Ok(vendored_proto_dir);
    }

    let workspace_proto_dir = manifest_dir.join("..").join("..").join("..").join("proto");
    if workspace_proto_dir.exists() {
        return Ok(workspace_proto_dir);
    }

    Err(format!(
        "Could not find proto directory. Looked in '{}' and '{}'.",
        vendored_proto_dir.display(),
        workspace_proto_dir.display()
    )
    .into())
}

fn main() -> Result<(), Box<dyn Error>> {
    let manifest_dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR")?);
    let proto_root = resolve_proto_root(&manifest_dir)?;
    let proto_files = collect_proto_files(&proto_root);

    if proto_files.is_empty() {
        return Err(format!("No .proto files found under '{}'.", proto_root.display()).into());
    }

    println!("cargo:rerun-if-changed=build.rs");
    for proto_file in &proto_files {
        println!("cargo:rerun-if-changed={}", proto_file.display());
    }

    let protoc_path = protoc_bin_vendored::protoc_bin_path()?;
    std::env::set_var("PROTOC", protoc_path);

    let mut config = prost_build::Config::new();
    config.bytes(["."]);
    config.type_attribute(".", "#[derive(serde::Serialize, serde::Deserialize)]");
    config.protoc_arg("--experimental_allow_proto3_optional");
    config.compile_protos(&proto_files, &[proto_root])?;

    Ok(())
}
