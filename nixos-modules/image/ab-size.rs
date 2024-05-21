use std::io::Write;

fn block_size(path: &std::path::Path) -> u64 {
    let full_path = path
        .canonicalize()
        .expect("couldn't get full path to block device");
    let sysfs_path = std::path::PathBuf::from("/sys/class/block")
        .join(full_path.file_name().expect("no filename"));

    u64::from_str_radix(
        std::fs::read_to_string(sysfs_path.join("size"))
            .expect("couldn't read size file")
            .trim(),
        10,
    )
    .expect("invalid contents in size file")
        * u64::from_str_radix(
            std::fs::read_to_string(
                sysfs_path
                    .canonicalize()
                    .expect("couldn't get full path from sysfs path")
                    .parent()
                    .expect("couldn't get parent of sysfs symlink")
                    .join("queue/logical_block_size"),
            )
            .expect("failed to read logical_block_size file")
            .trim(),
            10,
        )
        .expect("invalid contents of logical_block_size file")
}

fn update_repart_file(size: u64, path: &std::path::Path) {
    let mut file = std::fs::OpenOptions::new()
        .append(true)
        .open(path)
        .expect("failed to open repart conf file");

    file.write_all(format!("SizeMinBytes={0}\nSizeMaxBytes={0}\n", size).as_bytes())
        .expect("failed to update repart conf file");
}

fn main() {
    let mut args = std::env::args();
    _ = args.next();
    let max_usr_padding =
        u64::from_str_radix(&args.next().expect("missing max_usr_padding argument"), 10)
            .expect("invalid max_usr_padding argument");
    let max_usr_hash_padding = u64::from_str_radix(
        &args.next().expect("missing max_usr_hash_padding argument"),
        10,
    )
    .expect("invalid max_usr_hash_padding argument");

    let mut partlabel_dir =
        std::fs::read_dir("/dev/disk/by-partlabel").expect("failed to read /dev/disk/by-partlabel");

    let mut usr_size = None::<u64>;
    let mut usr_hash_size = None::<u64>;

    while let Some(Ok(entry)) = partlabel_dir.next() {
        let file_name = entry.file_name().into_string().expect("invalid UTF-8");

        if file_name.starts_with("usr-hash") {
            usr_hash_size = Some(block_size(entry.path().as_path()));
        } else if file_name.starts_with("usr-") {
            usr_size = Some(block_size(entry.path().as_path()));
        }

        if usr_size.is_some() && usr_hash_size.is_some() {
            break;
        }
    }

    let Some(usr_size) = usr_size else {
        eprintln!("couldn't find usr size");
        std::process::exit(1);
    };

    let Some(usr_hash_size) = usr_hash_size else {
        eprintln!("couldn't find usr-hash size");
        std::process::exit(1);
    };

    update_repart_file(
        usr_size + max_usr_padding,
        std::path::Path::new("/etc/repart.d/20-usr-a.conf"),
    );
    update_repart_file(
        usr_hash_size + max_usr_hash_padding,
        std::path::Path::new("/etc/repart.d/20-usr-hash-a.conf"),
    );
    update_repart_file(
        usr_size + max_usr_padding,
        std::path::Path::new("/etc/repart.d/30-usr-b.conf"),
    );
    update_repart_file(
        usr_hash_size + max_usr_hash_padding,
        std::path::Path::new("/etc/repart.d/30-usr-hash-b.conf"),
    );
}
