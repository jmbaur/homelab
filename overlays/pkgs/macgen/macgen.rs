use std::io::Read;

fn main() -> std::io::Result<()> {
    let mut urandom = std::fs::OpenOptions::new()
        .read(true)
        .open("/dev/urandom")?;

    let mut mac_bytes = [0u8; 6];

    urandom.read_exact(&mut mac_bytes)?;

    println!(
        "{}",
        mac_bytes
            .iter()
            .map(|byte| format!("{:02x}", byte))
            .collect::<Vec<String>>()
            .join(":")
    );

    Ok(())
}
