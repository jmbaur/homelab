use std::{
    path::PathBuf,
    time::{SystemTime, UNIX_EPOCH},
};

use flate2::read::GzDecoder;
use futures::StreamExt;
use tar::Archive;

#[tokio::main]
async fn main() -> Result<(), async_nats::Error> {
    let state_directory =
        PathBuf::from(std::env::var("STATE_DIRECTORY").expect("missing $STATE_DIRECTORY"));
    let _cache_directory =
        PathBuf::from(std::env::var("CACHE_DIRECTORY").expect("missing $CACHE_DIRECTORY"));
    let _runtime_directory =
        PathBuf::from(std::env::var("RUNTIME_DIRECTORY").expect("missing $RUNTIME_DIRECTORY"));

    let mut args = std::env::args();

    let _argv0 = args.next().expect("missing argv0");
    let nats_server_addr = args.next().expect("missing NATS server address");
    let ci_program = args.next().expect("missing CI program");

    let client = async_nats::connect(nats_server_addr).await?;
    let mut subscriber = client.subscribe("ci").await?;

    while let Some(message) = subscriber.next().await {
        let Ok(git_archive_path) = String::from_utf8(message.payload.to_vec()) else {
            eprintln!("invalid UTF8");
            continue;
        };
        println!("Received archive {}", &git_archive_path);

        let git_archive_path = PathBuf::from(git_archive_path);

        let Some(git_archive_name) = git_archive_path.file_name() else {
            eprintln!("no filename on git archive path");
            continue;
        };

        let mut git_archive_name = {
            let mut new_name = PathBuf::from(git_archive_name);
            while let Some(name) = new_name.file_stem() {
                new_name = PathBuf::from(name);
                if new_name.extension().is_none() {
                    break;
                }
            }
            new_name
        };

        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("failed to get time")
            .as_secs();

        git_archive_name.set_extension(timestamp.to_string());
        let unpack_path = state_directory.join(git_archive_name);

        let Ok(tar_gz) = std::fs::File::open(git_archive_path.as_path()) else {
            eprintln!("failed to open git archive");
            continue;
        };
        let tar = GzDecoder::new(tar_gz);
        let mut archive = Archive::new(tar);
        if let Err(err) = archive.unpack(&unpack_path) {
            eprintln!("failed to unpack git archive: {}", err);
            continue;
        };

        eprintln!("running {}", ci_program);
        let mut command = tokio::process::Command::new(&ci_program);
        command.current_dir(&unpack_path);

        if let Ok(mut child) = command.spawn() {
            _ = child.wait().await;
        }
    }

    Ok(())
}
