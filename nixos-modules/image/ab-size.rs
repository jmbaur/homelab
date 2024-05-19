use std::io::Write;

fn block_size(path: &std::path::Path) -> u64 {
    let full_path = path.canonicalize().unwrap();
    let sysfs_path = std::path::PathBuf::from(
        format!(
            "/sys/class/block/{}",
            full_path.file_name().unwrap().to_str().unwrap()
        )
        .as_str(),
    );

    u64::from_str_radix(
        std::fs::read_to_string(sysfs_path.join("size"))
            .unwrap()
            .trim(),
        10,
    )
    .unwrap()
        * u64::from_str_radix(
            std::fs::read_to_string(
                sysfs_path
                    .canonicalize()
                    .unwrap()
                    .parent()
                    .unwrap()
                    .join("queue/logical_block_size"),
            )
            .unwrap()
            .trim(),
            10,
        )
        .unwrap()
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
        usr_size,
        std::path::Path::new("/etc/repart.d/20-usr-a.conf"),
    );
    update_repart_file(
        usr_hash_size,
        std::path::Path::new("/etc/repart.d/20-usr-hash-a.conf"),
    );
    update_repart_file(
        usr_size,
        std::path::Path::new("/etc/repart.d/30-usr-b.conf"),
    );
    update_repart_file(
        usr_hash_size,
        std::path::Path::new("/etc/repart.d/30-usr-hash-b.conf"),
    );
}
