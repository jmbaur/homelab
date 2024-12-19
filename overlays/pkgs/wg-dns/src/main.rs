use std::{
    cmp::Ordering,
    thread::sleep,
    time::{Duration, Instant},
};

use anyhow::Context;
use base64::prelude::*;
use defguard_wireguard_rs::netlink::{get_host, set_peer};
use hickory_resolver::{
    config::{ResolverConfig, ResolverOpts},
    Resolver,
};

fn usage(argv0: &str) -> ! {
    eprintln!(
        "usage: {} <interface name> [<base64 peer public key> <peer dns name>]...",
        argv0
    );
    std::process::exit(1);
}

fn collect_peers(mut args: std::env::Args) -> anyhow::Result<Vec<(String, String)>> {
    let mut peers = Vec::new();

    loop {
        let Some(public_key) = args.next() else {
            break;
        };

        let dns_name = args.next().ok_or(anyhow::anyhow!(
            "missing dns name for wg peer with public key '{}'",
            public_key
        ))?;

        peers.push((dns_name, public_key));
    }

    Ok(peers)
}

fn main() -> anyhow::Result<()> {
    let mut args = std::env::args();

    let argv0 = args.next().context("missing argv[0]")?; // argv[0]

    let Some(wg_interface) = args.next() else {
        eprintln!("missing wireguard interface name");
        usage(&argv0)
    };

    let peers_to_update = match collect_peers(args) {
        Ok(peers) => peers,
        Err(err) => {
            eprintln!("{err}");
            usage(&argv0);
        }
    };

    let mut peers_to_update = peers_to_update.into_iter();

    let resolver = Resolver::new(ResolverConfig::default(), ResolverOpts::default())
        .expect("failed to initialize DNS resolver");

    let mut peers = Vec::new();

    let wg_host = get_host(&wg_interface)?;
    for (_, peer) in wg_host.peers {
        if peer.endpoint.is_none() {
            continue;
        }

        if let Some((dns_name, _)) = peers_to_update.find(|(_, public_key)| {
            BASE64_STANDARD
                .decode(public_key)
                .and_then(|public_key| Ok(public_key.as_slice() == peer.public_key.as_slice()))
                .unwrap_or_default()
        }) {
            peers.push((dns_name, None::<Instant>, peer));
        }
    }

    let mut peers_seen = 0;

    loop {
        // Sort so that Vec::pop() returns the peer with the smallest DNS response TTL.
        peers.sort_by(|(_, a, _), (_, b, _)| {
            if a > b {
                Ordering::Less
            } else {
                Ordering::Greater
            }
        });

        // If we've already tried to resolve the DNS name for all peers and they all failed, then
        // add an artificial wait to ensure we don't endlessly loop.
        if peers_seen >= peers.len()
            && peers
                .iter()
                .any(|(_, valid_until, _)| valid_until.is_some())
        {
            eprintln!("none of the peers have a DNS response with a valid TTL, adding artificial wait of 30 seconds");
            sleep(Duration::from_secs(30));
        }

        let Some((dns_name, valid_until, mut peer)) = peers.pop() else {
            // Nothing to do.
            break;
        };

        let mut endpoint = peer
            .endpoint
            .expect("already filtered out peers without endpoints");

        if let Some(valid_util) = valid_until {
            let time_to_wait = valid_util - Instant::now();
            eprintln!(
                "waiting {:?} until DNS name '{}' is no longer valid",
                time_to_wait, dns_name
            );
            sleep(time_to_wait);
        }

        if peers_seen < peers.len() {
            peers_seen += 1;
        }

        let valid_until = match resolver.lookup_ip(&dns_name) {
            Ok(response) => {
                // TODO(jared): don't just use first address
                match response.iter().next() {
                    Some(address) => {
                        if address != endpoint.ip() {
                            endpoint.set_ip(address);
                            peer.endpoint = Some(endpoint);
                            if let Err(err) = set_peer(&wg_interface, &peer) {
                                eprintln!("failed to set peer '{}': {err}", peer.public_key);
                            }
                        } else {
                            eprintln!(
                                "peer '{}' already has correct IP address, skipping",
                                peer.public_key
                            );
                        }
                    }
                    None => {
                        eprintln!("no addresses found for '{dns_name}'");
                    }
                };

                Some(response.valid_until())
            }
            Err(err) => {
                eprintln!("failed to resolve '{dns_name}': {err}");
                None
            }
        };

        peers.push((dns_name, valid_until, peer));
    }

    Ok(())
}
