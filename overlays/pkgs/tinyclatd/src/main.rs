use anyhow::Context;
use dbus::{
    arg::RefArg,
    blocking::{
        stdintf::org_freedesktop_dbus::PropertiesPropertiesChanged, LocalConnection, Proxy,
    },
    Message,
};
use libc::{SIGINT, SIGTERM};
use networkd_manager::OrgFreedesktopNetwork1Manager;
use serde::Deserialize;
use std::{
    cell::RefCell,
    io::Write,
    path::PathBuf,
    process::{Child, Command, ExitStatus},
    rc::Rc,
    str::FromStr,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    time::Duration,
};

mod networkd_manager {
    #![allow(non_upper_case_globals)]
    #![allow(non_camel_case_types)]
    #![allow(non_snake_case)]
    #![allow(unused)]
    include!(concat!(env!("OUT_DIR"), "/networkd_manager.rs"));
}

#[allow(unused)]
#[derive(Debug, Deserialize)]
struct PREF64 {
    #[serde(rename(deserialize = "Prefix"))]
    prefix: Vec<u8>,
    #[serde(rename(deserialize = "PrefixLength"))]
    prefix_length: u8,
    #[serde(rename(deserialize = "LifetimeUSec"))]
    lifetime_usec: u64,
    #[serde(rename(deserialize = "ConfigProvider"))]
    config_provider: Vec<u8>,
}

#[derive(Debug, Deserialize)]
struct NDisc {
    #[serde(rename(deserialize = "PREF64"))]
    pref64: Vec<PREF64>,
}

#[derive(Debug, Deserialize)]
struct Address {
    #[serde(rename(deserialize = "Family"))]
    family: libc::c_int,
    #[serde(rename(deserialize = "Scope"))]
    scope: libc::c_uchar,
}

#[derive(Debug, Deserialize)]
struct Link {
    #[serde(rename(deserialize = "NDisc"))]
    ndisc: Option<NDisc>,
    #[serde(rename(deserialize = "Addresses"))]
    addresses: Vec<Address>,
}

fn plat_prefix(networkd: &Proxy<&LocalConnection>) -> anyhow::Result<Option<Vec<PREF64>>> {
    let links = networkd.list_links().context("Failed to list links")?;

    let mut pref64 = None;

    for (ifindex, _, _) in links {
        let _link = dbg!(networkd
            .describe_link(ifindex)
            .context("Failed to describe link")?);

        let link: Link =
            serde_json::from_str(_link.as_str()).context("Failed to parse link json")?;

        // If we have a globally scoped IPv4 address, we have no need to setup a CLAT interface.
        for address in link.addresses {
            if address.family == libc::AF_INET && address.scope == libc::RT_SCOPE_UNIVERSE {
                return Ok(None);
            }
        }

        if let Some(ndisc) = link.ndisc {
            pref64 = Some(ndisc.pref64);
        }
    }

    Ok(pref64)
}

#[derive(Debug, PartialEq, Eq)]
enum OnlineState {
    Offline,
    Partial,
    Online,
}

impl FromStr for OnlineState {
    type Err = anyhow::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        use OnlineState::*;
        Ok(match s {
            "offline" => Offline,
            "partial" => Partial,
            "online" => Online,
            _ => anyhow::bail!("Invalid OnlineState"),
        })
    }
}

fn cleanup_clat() {}

fn clat_config(pref64: &PREF64) -> anyhow::Result<PathBuf> {
    let mut prefix_iter = pref64.prefix.clone().into_iter();
    let prefix_addr = std::net::Ipv6Addr::new(
        (prefix_iter.next().unwrap() as u16) << 8 | prefix_iter.next().unwrap() as u16,
        (prefix_iter.next().unwrap() as u16) << 8 | prefix_iter.next().unwrap() as u16,
        (prefix_iter.next().unwrap() as u16) << 8 | prefix_iter.next().unwrap() as u16,
        (prefix_iter.next().unwrap() as u16) << 8 | prefix_iter.next().unwrap() as u16,
        (prefix_iter.next().unwrap() as u16) << 8 | prefix_iter.next().unwrap() as u16,
        (prefix_iter.next().unwrap() as u16) << 8 | prefix_iter.next().unwrap() as u16,
        (prefix_iter.next().unwrap() as u16) << 8 | prefix_iter.next().unwrap() as u16,
        (prefix_iter.next().unwrap() as u16) << 8 | prefix_iter.next().unwrap() as u16,
    );

    let tmpdir =
        PathBuf::from(std::env::var("RUNTIME_DIRECTORY").unwrap_or_else(|_| String::from("/tmp")));
    let tayga_config_path = tmpdir.join("tayga_config");
    let mut tayga_config = std::fs::OpenOptions::new()
        .create(true)
        .write(true)
        .open(&tayga_config_path)
        .context("Failed to open tayga config")?;
    tayga_config
        .write_fmt(format_args!("tun-device {}\n", "clat0"))
        .context("Failed to write tayga config")?;
    tayga_config
        .write_fmt(format_args!(
            "prefix {}/{}\n",
            prefix_addr, pref64.prefix_length
        ))
        .context("Failed to write tayga config")?;
    tayga_config
        .write_fmt(format_args!("ipv4-addr {}\n", "192.0.0.2"))
        .context("Failed to write tayga config")?;
    tayga_config
        .write_fmt(format_args!("map {} {}\n", "192.0.0.1", "TODO"))
        .context("Failed to write tayga config")?;

    Ok(tayga_config_path)
}

fn fail_if_nonzero(msg: &'static str, status: ExitStatus) -> anyhow::Result<()> {
    match status.code() {
        Some(0) => anyhow::bail!(msg),
        _ => Ok(()),
    }
}

fn run_clat(pref64: PREF64) -> anyhow::Result<Child> {
    let configfile = clat_config(&pref64)?;

    fail_if_nonzero(
        "Failed to create tun device",
        Command::new("tayga")
            .arg("--config")
            .arg(&configfile)
            .arg("--mktun")
            .spawn()
            .context("Failed to spawn tayga")?
            .wait()
            .context("Failed to run tayga")?,
    )?;

    Ok(Command::new("tayga")
        .arg("--config")
        .arg(&configfile)
        .arg("--nodetach")
        .spawn()
        .context("Failed to spawn tayga")?)
}

fn main() -> anyhow::Result<()> {
    let conn = LocalConnection::new_system().context("Failed to open dbus connection")?;

    let networkd = conn.with_proxy(
        "org.freedesktop.network1",
        "/org/freedesktop/network1",
        Duration::from_millis(5000),
    );

    let stop = Arc::new(AtomicBool::new(false));
    _ = signal_hook::flag::register(SIGTERM, Arc::clone(&stop));
    _ = signal_hook::flag::register(SIGINT, Arc::clone(&stop));

    // Start with true so we do initial setup of the CLAT.
    let online_state_changed = Rc::new(AtomicBool::new(true));

    let online_state = Rc::new(RefCell::new(OnlineState::from_str(
        networkd
            .online_state()
            .context("Failed to get OnlineState")?
            .as_str(),
    )?));

    let _online_state = online_state.clone();
    let _online_state_changed = online_state_changed.clone();
    let token = networkd
        .match_signal(
            move |mut signal: PropertiesPropertiesChanged, _: &LocalConnection, _: &Message| {
                if let Some(Some(Ok(new_online_state))) = signal
                    .changed_properties
                    .remove("OnlineState")
                    .map(|variant| variant.as_str().map(|s| OnlineState::from_str(s)))
                {
                    *_online_state.borrow_mut() = new_online_state;
                    _online_state_changed.store(true, Ordering::SeqCst);
                }
                true
            },
        )
        .context("Failed to add signal match on networkd properties changed")?;

    let (tx, rx) = std::sync::mpsc::channel::<Option<PREF64>>();

    let thread_handle = std::thread::spawn(move || {
        let mut child: Option<Child> = None;

        while let Ok(pref64) = rx.recv() {
            if let Some(child) = child.as_mut() {
                child.kill().expect("Failed to kill tayga");
                cleanup_clat();
            }

            if let Some(pref64) = pref64 {
                child = Some(run_clat(pref64).expect("Failed to run tayga"));
            }
        }
    });

    loop {
        if stop.load(Ordering::Relaxed) {
            tx.send(None).context("Failed to send message to thread")?;
            break;
        }

        if online_state_changed.load(Ordering::Relaxed) {
            online_state_changed.store(false, Ordering::SeqCst);

            if *online_state.borrow() != OnlineState::Offline {
                // TODO(jared): don't only use the first PLAT prefix found
                if let Some(pref64) = plat_prefix(&networkd)?
                    .map(|plats| plats.into_iter().take(1).next())
                    .flatten()
                {
                    tx.send(Some(pref64))
                        .context("Failed to send message to thread")?;
                }
            }
        }

        _ = conn
            .process(Duration::from_millis(5000))
            .context("Failed to process dbus messages")?;
    }

    drop(tx);
    thread_handle.join().expect("Failed to join thread");
    conn.remove_match(token)
        .context("Failed to remove match token")?;

    Ok(())
}
