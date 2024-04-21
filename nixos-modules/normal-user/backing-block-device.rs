/// Given an arbitrary path, find the block device backing that path.
///
/// Usage: backing-block-device <path>
///
use std::str::FromStr;

#[derive(Debug)]
enum Error {
    InvalidPath,
    MissingWhat,
    MissingFsType,
    MissingMountPoint,
    MissingSearchPath,
    NoBackingDevice,
    ReadFailure,
    UnknownFsType,
}

#[derive(Debug)]
enum FsType {
    Btrfs,
    Ext4,
    F2fs,
    Overlay,
    Sysfs,
    Tmpfs,
    Bpf,
    Portal,
    Configfs,
    Efivarfs,
    Devtmpfs,
    Devpts,
}

impl std::str::FromStr for FsType {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(match s {
            "ext4" => Self::Ext4,
            "btrfs" => Self::Btrfs,
            "f2fs" => Self::F2fs,
            "overlay" => Self::Overlay,
            "sysfs" => Self::Sysfs,
            "tmpfs" => Self::Tmpfs,
            "bpf" => Self::Bpf,
            "portal" => Self::Portal,
            "configfs" => Self::Configfs,
            "efivarfs" => Self::Efivarfs,
            "devtmpfs" => Self::Devtmpfs,
            "devpts" => FsType::Devpts,
            _ => return Err(Self::Err::UnknownFsType),
        })
    }
}

impl std::fmt::Display for FsType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                FsType::Btrfs => "btrfs",
                FsType::Ext4 => "ext4",
                FsType::F2fs => "f2fs",
                FsType::Overlay => "overlay",
                FsType::Sysfs => "sysfs",
                FsType::Tmpfs => "tmpfs",
                FsType::Bpf => "bpf",
                FsType::Portal => "portal",
                FsType::Configfs => "configfs",
                FsType::Efivarfs => "efivarfs",
                FsType::Devtmpfs => "devtmpfs",
                FsType::Devpts => "devpts",
            }
        )
    }
}

#[derive(Debug)]
struct Mount {
    what: String,
    mountpoint: std::path::PathBuf,
    fs_type: FsType,
}

fn parse_proc_mount_line(mount: &str) -> Result<Mount, Error> {
    let mut split = mount.split_whitespace();
    let what = split.next().ok_or(Error::MissingWhat)?.to_string();

    let mountpoint = std::path::PathBuf::from_str(split.next().ok_or(Error::MissingMountPoint)?)
        .or_else(|_| Err(Error::InvalidPath))?;

    let fs_type = FsType::from_str(split.next().ok_or(Error::MissingFsType)?)?;

    Ok(Mount {
        what,
        mountpoint,
        fs_type,
    })
}

struct CloseMount {
    score: u8,
    mount: Mount,
}

/// Lowest score wins.
fn closeness_score(
    search_path: &std::path::Path,
    mountpoint: &std::path::Path,
    start: u8,
) -> Option<u8> {
    if search_path == mountpoint {
        return Some(start);
    }

    if let Some(parent) = search_path.parent() {
        return closeness_score(parent, mountpoint, start + 1);
    } else {
        return None;
    }
}

fn main() -> Result<(), Error> {
    let mut args = std::env::args();
    let search_path =
        std::path::PathBuf::from_str(args.nth(1).ok_or(Error::MissingSearchPath)?.as_str())
            .or_else(|_| Err(Error::InvalidPath))?;

    let mut closest: Option<CloseMount> = None;

    let mounts = std::fs::read_to_string("/proc/mounts").or_else(|_| Err(Error::ReadFailure))?;
    for mount in mounts.lines() {
        if let Ok(mount) = parse_proc_mount_line(mount) {
            let Some(score) = closeness_score(search_path.as_path(), mount.mountpoint.as_path(), 0)
            else {
                continue;
            };

            if let Some(current_closest) = closest.as_ref() {
                if score < current_closest.score {
                    closest = Some(CloseMount { score, mount });
                }
            } else {
                closest = Some(CloseMount { score, mount });
            }
        }
    }

    if let Some(closest) = closest {
        let block_device = std::path::PathBuf::from_str(closest.mount.what.as_str())
            .or_else(|_| Err(Error::InvalidPath))?;

        // If the "what" is not an absolute path, we know it is not a block device. For example, a
        // tmpfs mount's what is just "tmpfs".
        if !block_device.is_absolute() {
            return Err(Error::InvalidPath);
        }

        println!(
            "{{\"block_device\":\"{}\",\"fs_type\":\"{}\",\"mount_point\":\"{}\"}}",
            block_device.display(),
            closest.mount.fs_type,
            closest.mount.mountpoint.display(),
        );

        return Ok(());
    }

    Err(Error::NoBackingDevice)
}
