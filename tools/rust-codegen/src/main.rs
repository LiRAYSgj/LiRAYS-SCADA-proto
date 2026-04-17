use std::error::Error;
use std::ffi::OsStr;
use std::fs;
use std::path::{Path, PathBuf};

fn collect_proto_files(proto_root: &Path) -> Result<Vec<PathBuf>, Box<dyn Error>> {
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
    Ok(files)
}

fn clear_stale_rs_files(out_dir: &Path) -> Result<(), Box<dyn Error>> {
    if !out_dir.exists() {
        fs::create_dir_all(out_dir)?;
        return Ok(());
    }

    for entry in fs::read_dir(out_dir)? {
        let path = entry?.path();
        if path.extension() == Some(OsStr::new("rs")) {
            fs::remove_file(path)?;
        }
    }

    Ok(())
}

fn main() -> Result<(), Box<dyn Error>> {
    let mut args = std::env::args_os();
    let _ = args.next();

    let proto_root = PathBuf::from(
        args.next()
            .ok_or("missing argument: <proto_root>")?,
    );
    let out_dir = PathBuf::from(
        args.next()
            .ok_or("missing argument: <out_dir>")?,
    );

    if !proto_root.exists() {
        return Err(format!("proto root does not exist: {}", proto_root.display()).into());
    }

    let proto_files = collect_proto_files(&proto_root)?;
    if proto_files.is_empty() {
        return Err("no .proto files found".into());
    }

    clear_stale_rs_files(&out_dir)?;

    let protoc_path = protoc_bin_vendored::protoc_bin_path()?;
    std::env::set_var("PROTOC", protoc_path);

    let mut config = prost_build::Config::new();
    config.out_dir(&out_dir);
    config.bytes(["."]);
    config.protoc_arg("--experimental_allow_proto3_optional");

    config.compile_protos(&proto_files, &[proto_root])?;

    Ok(())
}
