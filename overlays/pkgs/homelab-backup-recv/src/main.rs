use std::{
    collections::HashMap,
    net::{IpAddr, Ipv6Addr, TcpListener, TcpStream},
    path::{Path, PathBuf},
    process::Stdio,
};

type Peers = HashMap<Ipv6Addr, String>;

fn handle_connection(mut stream: TcpStream, peers: Peers, snapshot_root: PathBuf) {
    let peer = stream.peer_addr().unwrap();

    let mut ip = peer.ip();

    loop {
        match ip {
            IpAddr::V4(addr) => eprintln!("peer has invalid address '{}'", addr),
            IpAddr::V6(addr) => {
                let canonical = addr.to_canonical();

                if canonical != ip {
                    ip = canonical;
                    continue;
                }

                let Some(name) = peers.get(&addr) else {
                    eprintln!("address {} not found in peers", addr);
                    return;
                };

                let mut child = std::process::Command::new("btrfs")
                    .stdin(Stdio::piped())
                    .stdout(Stdio::null())
                    .stderr(Stdio::null())
                    .arg("receive")
                    .arg(snapshot_root.join(name))
                    .spawn()
                    .unwrap();

                let mut stdin = child.stdin.take().unwrap();

                std::io::copy(&mut stream, &mut stdin).unwrap();

                let status = child.wait().unwrap();

                if status.success() {
                    eprintln!("{} successfully backed up", name);
                }
            }
        }

        break;
    }
}

fn parse_peer_file(file: &Path) -> std::io::Result<Peers> {
    let mut peers = HashMap::new();

    let contents = std::fs::read_to_string(file)?;

    for line in contents.lines() {
        let mut split = line.split_whitespace();

        let Some(name) = split.next() else {
            eprintln!("invalid line '{}'", line);
            continue;
        };

        let Some(ip) = split.next() else {
            eprintln!("invalid line '{}'", line);
            continue;
        };

        let Ok(ip) = ip.parse() else {
            eprintln!("invalid line '{}'", line);
            continue;
        };

        peers.insert(ip, name.to_string());
    }

    Ok(peers)
}

fn main() {
    let mut args = std::env::args();

    let _argv0 = args.next().expect("missing argv0");

    let peer_file = PathBuf::from(args.next().expect("missing peer file"));

    let snapshot_root = PathBuf::from(args.next().expect("missing snapshot root"));

    let port = args
        .next()
        .map(|port| u16::from_str_radix(&port, 10).expect("invalid port"))
        .expect("missing port");

    let peers = parse_peer_file(&peer_file).expect("invalid peer file");

    for (ip, peer) in peers.iter() {
        eprintln!("using peer '{}' at {}", peer, ip);
    }

    let listener = TcpListener::bind(format!("[::]:{}", port)).expect("failed to spawn listener");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let peers = peers.clone();
                let snapshot_root = snapshot_root.clone();
                _ = std::thread::spawn(move || handle_connection(stream, peers, snapshot_root));
            }
            Err(err) => {
                eprintln!("connection failed: {}", err);
            }
        }
    }
}
