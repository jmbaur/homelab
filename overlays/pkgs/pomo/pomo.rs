use std::io::Write;

static IN_TMUX: std::sync::OnceLock<bool> = std::sync::OnceLock::new();

macro_rules! printf {
    ($($args:tt),*) => {{
        print!("\x1b[2K");
        print!("\x1b[100D");
        print!($($args),*);
        std::io::stdout().flush().expect("flush");
    }};
}

macro_rules! notifyf {
    ($($args:tt),*) => {{
        let in_tmux = IN_TMUX.get().unwrap_or(&false);

        if *in_tmux {
            print!("\x1bPtmux;\x1b");
        }

        print!("\x1b]777;notify;pomodoro;{}\x1b\x5c", format!($($args),*));

        if *in_tmux {
            print!("\x1b\\");
        }

        print!("\x07"); // bell
        std::io::stdout().flush().expect("flush");
    }};
}

fn pomo(status: &str, d: std::time::Duration) {
    print!("\x1b[2J");
    print!("\x1b[0;0H");
    notifyf!("{}", status);
    println!("{}", status);

    let (tx, rx) = std::sync::mpsc::channel::<()>();

    let handle = std::thread::spawn(move || {
        let start = std::time::Instant::now();
        loop {
            match rx.recv_timeout(std::time::Duration::from_secs(1)) {
                Err(std::sync::mpsc::RecvTimeoutError::Timeout) => {
                    let now = std::time::Instant::now();
                    let diff = now - start;
                    if diff == std::time::Duration::from_secs(30) {
                        notifyf!("30 seconds left!");
                    }
                    let time_left = d - diff;
                    let time_left_display = if time_left > std::time::Duration::from_secs(60) {
                        format!("{}min", time_left.as_secs().div_ceil(60))
                    } else {
                        format!("{}sec", time_left.as_secs())
                    };
                    printf!("{}", time_left_display);
                }
                _ => break,
            }
        }
    });

    std::thread::sleep(d);
    tx.send(()).expect("could not send to thread");
    handle.join().expect("could not join thread handle");
}

fn main() {
    _ = IN_TMUX.get_or_init(|| std::env::var("TMUX").is_ok());

    loop {
        for _ in 0..4 {
            pomo("work!", std::time::Duration::from_secs(25 * 60));
            pomo("break!", std::time::Duration::from_secs(5 * 60));
        }
        pomo("long break!", std::time::Duration::from_secs(30 * 60));

        println!("Press <ENTER> to continue to the next pomodoro session, CTRL-C to quit.");
        let mut lines = std::io::stdin().lines();
        _ = lines.next();
    }
}
