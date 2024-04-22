use std::os::unix::io::{FromRawFd, IntoRawFd};

type MyResult<T> = std::result::Result<T, String>;

trait Context<T> {
    fn context(self, msg: impl Into<String>) -> MyResult<T>;
}

impl<T> Context<T> for std::io::Result<T> {
    fn context(self, msg: impl Into<String>) -> MyResult<T> {
        match self {
            Err(err) => Err(format!("{}: {}", msg.into(), err)),
            Ok(ok) => Ok(ok),
        }
    }
}

macro_rules! fail {
    ($($args:tt),*) => {{
        return Err((format!($($args),*)));
    }};
}

fn mount(
    fs_type: &str,
    read_only: bool,
    what: impl AsRef<std::ffi::OsStr> + std::fmt::Debug,
    mountpoint: impl AsRef<std::ffi::OsStr> + std::fmt::Debug,
) -> MyResult<()> {
    let mut args = Vec::new();

    if read_only {
        args.push(std::ffi::OsStr::new("-r"));
    }

    args.append(&mut vec![
        std::ffi::OsStr::new("-t"),
        std::ffi::OsStr::new(fs_type),
        what.as_ref(),
        mountpoint.as_ref(),
    ]);

    let output = std::process::Command::new("/bin/mount")
        .args(&args)
        .spawn()
        .context("failed to spawn mount")?
        .wait_with_output()
        .context("failed to run mount")?;

    if !output.status.success() {
        fail!("failed to mount {:?} to {:?}", what, mountpoint);
    }

    Ok(())
}

fn unmount(mountpoint: impl AsRef<std::ffi::OsStr> + std::fmt::Debug) -> MyResult<()> {
    let output = std::process::Command::new("/bin/umount")
        .args(&[&mountpoint])
        .spawn()
        .context("failed to spawn umount")?
        .wait_with_output()
        .context("failed to run umount")?;

    if !output.status.success() {
        fail!("failed to unmount {:?}", mountpoint);
    }

    Ok(())
}

fn udev_settle() -> MyResult<()> {
    std::process::Command::new("/opt/systemd/bin/udevadm")
        .args(&["trigger", "--action=add"])
        .spawn()
        .context("failed to spawn udevadm trigger")?
        .wait()
        .context("failed to run udevadm trigger")?;

    std::process::Command::new("/opt/systemd/bin/udevadm")
        .args(&["settle"])
        .spawn()
        .context("failed to spawn udevadm settle")?
        .wait()
        .context("failed to run udevadm settle")?;

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

fn reboot() -> MyResult<()> {
    std::process::Command::new("/bin/reboot")
        .spawn()
        .context("failed to spawn /bin/reboot")?
        .wait()
        .context("failed to run /bin/reboot")?;

    Ok(())
}

fn chvt(num: u8) -> MyResult<()> {
    std::process::Command::new("/bin/chvt")
        .arg(num.to_string())
        .spawn()
        .context("failed to spawn /bin/chvt")?
        .wait()
        .context("failed to run /bin/chvt")?;

    Ok(())
}

fn real_main(reboot_on_fail: &mut bool) -> MyResult<()> {
    eprintln!("{0} INSTALLER {0}", "#".repeat(30));

    let proc_cmdline =
        std::fs::read_to_string("/proc/cmdline").context("failed to read /proc/cmdline")?;
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
            Some(("installer", "reboot_on_fail")) => {
                *reboot_on_fail = val != "0";
            }
            _ => {}
        }
    }

    let Some(source_disk) = source_disk else {
        fail!("no source disk specified");
    };

    let Some(target_disk) = target_disk else {
        fail!("no target disk specified");
    };

    eprintln!("waiting for devices to settle...");
    udev_settle()?;

    let source_disk = std::fs::canonicalize(source_disk).context("no source disk found")?;
    let target_disk = std::fs::canonicalize(target_disk).context("no target disk found")?;

    eprintln!("installing from {}", source_disk.display());
    eprintln!("installing to {}", target_disk.display());

    let mountpoint = std::path::Path::new("/mnt");
    std::fs::create_dir_all(&mountpoint).context("failed to create mountpoint")?;
    mount("ext4", true, &source_disk, &mountpoint)?;

    let in_file = std::fs::OpenOptions::new()
        .read(true)
        .open(mountpoint.join("image"))
        .context("failed to open image to install")?;

    let out_file = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(target_disk)
        .context("failed to open target disk")?;

    // TODO(jared): Make a custom Into<Stdio> implementation that prints progress of copying the
    // image to the target disk.
    eprintln!("copying image...");
    let output = std::process::Command::new("/bin/xz")
        .arg("-d")
        .stdin(unsafe { std::process::Stdio::from_raw_fd(in_file.into_raw_fd()) })
        .stdout(unsafe { std::process::Stdio::from_raw_fd(out_file.into_raw_fd()) })
        .spawn()
        .context("xz failed to spawn")?
        .wait_with_output()
        .context("xz failed to run")?;

    if !output.status.success() {
        fail!("failed to decompress image");
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

fn main() -> ! {
    let mut reboot_on_fail = false;

    if let Err(err) = real_main(&mut reboot_on_fail) {
        eprintln!("failed to perform installation: {:?}", err);

        if reboot_on_fail {
            eprintln!("rebooting in 10 seconds");
            std::thread::sleep(std::time::Duration::from_secs(10));
            if let Err(err) = reboot() {
                eprintln!("failed to reboot: {}", err);
            }
        } else {
            eprintln!("changing to /dev/tty2 in 10 seconds");
            std::thread::sleep(std::time::Duration::from_secs(10));
            if let Err(err) = chvt(2) {
                eprintln!("failed to chvt: {}", err);
            }
        }
    }

    loop {
        use std::io::Read;
        let mut buf = [0u8; 1];
        _ = std::io::stdin().read(&mut buf);
    }
}
