use std::os::unix::io::{FromRawFd, IntoRawFd};

type Result<T> = std::result::Result<T, String>;

trait Context<T> {
    fn context(self, msg: impl Into<String>) -> Result<T>;
}

impl<T> Context<T> for Result<T> {
    fn context(self, msg: impl Into<String>) -> Result<T> {
        match self {
            Err(err) => Err(format!("{}: {}", msg.into(), err)),
            Ok(ok) => Ok(ok),
        }
    }
}

impl<T> Context<T> for Option<T> {
    fn context(self, msg: impl Into<String>) -> Result<T> {
        match self {
            Some(some) => Ok(some),
            None => Err(format!("{}: expected Some", msg.into())),
        }
    }
}

impl<T> Context<T> for std::io::Result<T> {
    fn context(self, msg: impl Into<String>) -> Result<T> {
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
) -> Result<()> {
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

fn unmount(mountpoint: impl AsRef<std::ffi::OsStr> + std::fmt::Debug) -> Result<()> {
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

fn udev_settle() -> Result<()> {
    std::process::Command::new("/bin/udevadm")
        .args(&["trigger", "--action=add"])
        .spawn()
        .context("failed to spawn udevadm trigger")?
        .wait()
        .context("failed to run udevadm trigger")?;

    std::process::Command::new("/bin/udevadm")
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

extern "C" {
    pub fn kill(pid: std::ffi::c_int, signal: std::ffi::c_int) -> std::ffi::c_int;
}

const SIGTERM: std::ffi::c_int = 15;

fn reboot() -> Result<()> {
    _ = unsafe {
        kill(1, SIGTERM);
    };

    Ok(())
}

fn shell() -> Result<()> {
    std::process::Command::new("/bin/sh")
        .arg("-l")
        .spawn()
        .context("failed to spawn /bin/sh")?
        .wait()
        .context("failed to run /bin/sh")?;

    Ok(())
}

fn wait_for_path(path: &str) -> Result<std::path::PathBuf> {
    for _ in 0..10 {
        match std::fs::canonicalize(path) {
            Ok(path) => return Ok(path),
            Err(err) => match err.kind() {
                std::io::ErrorKind::NotFound => {
                    std::thread::sleep(std::time::Duration::from_secs(1))
                }
                _ => return Err(err).context("failed to canonicalize path")?,
            },
        }
    }

    fail!("path {} not found", path);
}

fn real_main() -> Result<()> {
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

    {
        eprintln!("press ENTER to drop to a shell");
        let (tx, rx) = std::sync::mpsc::channel::<()>();
        let _thread_handle = std::thread::spawn(move || {
            let mut input = String::new();
            match std::io::stdin().read_line(&mut input) {
                Ok(_) => _ = tx.send(()),
                Err(_) => {}
            }
        });

        match rx.recv_timeout(std::time::Duration::from_millis(2500)) {
            Ok(_) => fail!("requested a shell"),
            Err(_) => eprintln!("continuing with installation"),
        }
    }

    let source_disk_part = wait_for_path(source_disk).context("failed to find source disk")?;
    let target_disk = wait_for_path(target_disk).context("failed to find target disk")?;

    // Make sure source_disk != target_disk
    {
        let source_disk_part_sysfs = std::fs::canonicalize(
            std::path::Path::new("/sys/class/block").join(
                source_disk_part
                    .file_name()
                    .context("failed to get filename of source disk partition")?,
            ),
        )
        .context("failed to get full path to source disk partition sysfs entry")?;

        let target_disk_sysfs = std::fs::canonicalize(
            std::path::Path::new("/sys/class/block").join(
                target_disk
                    .file_name()
                    .context("failed to get filename of target disk")?,
            ),
        )
        .context("failed to get full path to target disk sysfs entry")?;

        if source_disk_part_sysfs
            .parent()
            .context("failed to get parent of source disk sysfs entry")?
            == target_disk_sysfs.as_path()
        {
            fail!("source disk is the same as target disk, cannot install");
        }
    }

    eprintln!("installing from {}", source_disk_part.display());
    eprintln!("installing to {}", target_disk.display());

    let mountpoint = std::path::Path::new("/mnt");
    std::fs::create_dir_all(&mountpoint).context("failed to create mountpoint")?;
    mount("ext4", true, &source_disk_part, &mountpoint)?;

    let in_file = std::fs::OpenOptions::new()
        .read(true)
        .open(mountpoint.join("image"))
        .context("failed to open image to install")?;

    let mut out_file = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(target_disk)
        .context("failed to open target disk")?;

    eprintln!("copying image...");
    let mut child = std::process::Command::new("/bin/xz")
        .arg("-d")
        .stdin(unsafe { std::process::Stdio::from_raw_fd(in_file.into_raw_fd()) })
        .stdout(std::process::Stdio::piped())
        .spawn()
        .context("xz failed to spawn")?;

    let mut stdout = child
        .stdout
        .take()
        .context("failed to open stdout of child")?;

    let handle = std::thread::spawn(move || {
        use std::io::{Read, Write};

        let mut lock = std::io::stdout().lock();

        let mut buf = [0u8; 4096];
        let mut bytes_written: usize = 0;

        loop {
            match stdout.read(&mut buf[..]) {
                Ok(0) => break,
                Ok(n) => {
                    bytes_written += n;
                    out_file.write_all(&buf[0..n]).unwrap();

                    // Print progress after every 64MiB
                    if bytes_written >= 1 << 26 {
                        bytes_written = 0;
                        write!(lock, "#").unwrap();
                        lock.flush().unwrap();
                    }
                }
                Err(err) => {
                    eprintln!("write to disk failed: {}", err);
                    panic!();
                }
            }
        }
        write!(lock, "\n").unwrap();
    });

    let output = child.wait_with_output().context("xz failed to run")?;

    _ = handle.join();

    if !output.status.success() {
        fail!("failed to decompress image");
    }

    eprintln!("installation finished");

    unmount(&mountpoint)?;

    eprintln!(
        "system will reboot when {} is removed/unplugged",
        source_disk_part.display()
    );
    wait_until_gone(&source_disk_part);

    reboot()?;

    Ok(())
}

fn main() -> ! {
    if let Err(err) = real_main() {
        eprintln!("failed to perform installation: {:?}", err);

        eprintln!("dropping to a shell");
        std::thread::sleep(std::time::Duration::from_millis(2500));
        loop {
            if let Err(err) = shell() {
                eprintln!("failed to spawn shell: {}", err);
            }
        }
    }

    // When reboot is called, we must wait here until the reboot takes place.
    loop {
        use std::io::Read;
        let mut buf = [0u8; 1];
        _ = std::io::stdin().read(&mut buf);
    }
}
