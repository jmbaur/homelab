use std::path::PathBuf;

fn main() {
    let mut args = std::env::args();

    let argv0 = args.next().expect("missing argv0");
    let argv0 = PathBuf::from(argv0);
    let argv0 = argv0.file_name().expect("missing argv0");

    eprintln!("{:?}", argv0);
}
