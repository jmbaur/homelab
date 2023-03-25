use clap::Parser;
use evdev::{Device, Key};

#[derive(clap::ValueEnum, Clone)]
enum Action {
    Restart,
}

#[derive(clap::Parser)]
#[command(name = "dookie")]
struct Cli {
    #[arg(short, long)]
    device: std::path::PathBuf,
    #[arg(short, long)]
    key_code: u16,
    #[arg(short, long, value_enum)]
    action: Action,
}

fn main() -> std::io::Result<()> {
    let cli = Cli::parse();

    let device = Device::open(&cli.device)?;

    let key = Key::new(cli.key_code);

    if device
        .supported_keys()
        .map_or(false, |keys| keys.contains(key))
    {
        eprintln!("device {:?} does not support key {:?}", &cli.device, key);
        std::process::exit(1);
    }

    loop {
        let key_state = device.get_key_state()?;
        if key_state.contains(key) {
            match cli.action {
                Action::Restart => {
                    // According to systemd(1), SIGRTMIN+5 reboots the machine by starting the
                    // reboot.target unit.
                    unsafe { libc::kill(1, libc::SIGRTMIN() + 5) };
                }
            }
        }

        std::thread::sleep(std::time::Duration::from_millis(500));
    }
}
