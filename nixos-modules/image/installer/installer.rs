use std::os::unix::io::{FromRawFd, IntoRawFd};

#[derive(Debug)]
enum Error {
    Decompress,
    Mount,
    NoSourceDisk,
    NoTargetDisk,
    Unmount,

    Io(#[allow(dead_code)] std::io::Error),
}

impl From<std::io::Error> for Error {
    fn from(value: std::io::Error) -> Self {
        Self::Io(value)
    }
}

type Result<T> = std::result::Result<T, Error>;

fn mount(
    fs_type: &str,
    read_only: bool,
    what: &std::ffi::OsStr,
    mountpoint: impl AsRef<std::ffi::OsStr>,
) -> Result<()> {
    let mut args = Vec::new();

    if read_only {
        args.push(std::ffi::OsStr::new("-r"));
    }

    args.append(&mut vec![
        std::ffi::OsStr::new("-t"),
        std::ffi::OsStr::new(fs_type),
        what,
        mountpoint.as_ref(),
    ]);

    let status = std::process::Command::new("/bin/mount")
        .args(&args)
        .spawn()?
        .wait()?;

    if status.success() {
        Ok(())
    } else {
        Err(Error::Mount)
    }
}

fn unmount(mountpoint: impl AsRef<std::ffi::OsStr>) -> Result<()> {
    let status = std::process::Command::new("/bin/umount")
        .args(&[mountpoint])
        .spawn()?
        .wait()?;

    if status.success() {
        Ok(())
    } else {
        Err(Error::Unmount)
    }
}

fn udev_settle() -> Result<()> {
    std::process::Command::new("/opt/systemd/bin/udevadm")
        .args(&["trigger", "--action=add"])
        .spawn()?
        .wait()?;

    std::process::Command::new("/opt/systemd/bin/udevadm")
        .args(&["settle"])
        .spawn()?
        .wait()?;

    Ok(())
}

fn wait_until_gone(path: &std::path::Path) {
    loop {
        match std::fs::metadata(path) {
            Ok(_) => {}
            Err(err) => match err.kind() {
                std::io::ErrorKind::NotFound => break,
                _ => {}
            },
        }

        std::thread::sleep(std::time::Duration::from_secs(1));
    }
}

fn reboot() -> Result<()> {
    std::process::Command::new("/bin/reboot").spawn()?.wait()?;

    Ok(())
}

fn main() -> ! {
    if let Err(err) = real_main() {
        eprintln!("failed to perform installation: {:?}", err);
    }

    loop {
        eprintln!("rebooting in 10 seconds");
        std::thread::sleep(std::time::Duration::from_secs(10));

        if let Err(err) = reboot() {
            eprintln!("failed to reboot: {:?}", err);
        }
    }
}

fn real_main() -> Result<()> {
    eprintln!("{0} INSTALLER {0}", "#".repeat(30));

    let proc_cmdline = std::fs::read_to_string("/proc/cmdline")?;
    let mut proc_cmdline_split = proc_cmdline.split_whitespace();

    let mut source_disk = None;
    let mut target_disk = None;

    while let Some(arg) = proc_cmdline_split.next() {
        let Some((key, val)) = arg.split_once('=') else {
            continue;
        };

        match key.split_once('.') {
            Some(("installer", "source_disk")) => {
                source_disk = Some(val);
            }
            Some(("installer", "target_disk")) => {
                target_disk = Some(val);
            }
            _ => {}
        }
    }

    let Some(source_disk) = source_disk else {
        return Err(Error::NoSourceDisk);
    };

    let Some(target_disk) = target_disk else {
        return Err(Error::NoTargetDisk);
    };

    eprintln!("waiting for devices to settle...");
    udev_settle()?;

    let source_disk = std::fs::canonicalize(source_disk)?;
    let target_disk = std::fs::canonicalize(target_disk)?;

    eprintln!("installing from {}", source_disk.display());
    eprintln!("installing to {}", target_disk.display());

    let mountpoint = std::path::Path::new("/mnt");
    std::fs::create_dir_all(&mountpoint)?;
    mount(
        "ext4",
        true,
        source_disk.as_os_str(),
        &mountpoint,
    )?;

    let in_file = std::fs::OpenOptions::new()
        .read(true)
        .open(mountpoint.join("image"))?;

    let out_file = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(target_disk)?;

    // TODO(jared): Make a custom Into<Stdio> implementation that prints progress of copying the
    // image to the target disk.
    eprintln!("copying image...");
    let status = std::process::Command::new("/bin/xz")
        .arg("-d")
        .stdin(unsafe { std::process::Stdio::from_raw_fd(in_file.into_raw_fd()) })
        .stdout(unsafe { std::process::Stdio::from_raw_fd(out_file.into_raw_fd()) })
        .spawn()?
        .wait()?;

    if !status.success() {
        return Err(Error::Decompress);
    }

    eprintln!("installation finished");

    unmount(&mountpoint)?;

    eprintln!(
        "system will reboot when {} is removed/unplugged",
        source_disk.display()
    );
    wait_until_gone(&source_disk);

    reboot()?;

    Ok(())
}
