use std::{
    path::PathBuf,
    process::Stdio,
    time::{Duration, SystemTime, UNIX_EPOCH},
};

use anyhow::Context;
use flate2::read::GzDecoder;
use futures::StreamExt;
use tar::Archive;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};

enum Input {
    Nats(String),
    File(String),
}

fn parse_input_specifier(specifier: &str) -> anyhow::Result<Input> {
    let Some((key, value)) = specifier.split_once(':') else {
        anyhow::bail!("invalid input specifier");
    };

    match key {
        "nats" => Ok(Input::Nats(value.to_string())),
        "file" => Ok(Input::File(if value.is_empty() {
            "/dev/stdin".to_string()
        } else {
            value.to_string()
        })),
        other => anyhow::bail!("invalid input type '{}'", other),
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let state_directory =
        PathBuf::from(std::env::var("STATE_DIRECTORY").expect("missing $STATE_DIRECTORY"));

    let mut args = std::env::args();

    let _argv0 = args.next().expect("missing argv0");
    let input = args.next().expect("missing input specifier");
    let ci_program = args.next().expect("missing CI program");

    match parse_input_specifier(&input)? {
        Input::Nats(nats_server_addr) => {
            let client = async_nats::connect(nats_server_addr).await?;
            let mut subscriber = client.subscribe("ci").await?;
            while let Some(message) = subscriber.next().await {
                let Ok(git_archive_path) = String::from_utf8(message.payload.to_vec()) else {
                    eprintln!("invalid UTF8");
                    continue;
                };

                if let Err(err) =
                    handle_archive(&state_directory, &ci_program, &git_archive_path).await
                {
                    eprintln!("failed to handle archive: {err}");
                }
            }
        }
        Input::File(filepath) => {
            let input_file = tokio::fs::OpenOptions::new()
                .read(true)
                .open(&filepath)
                .await?;

            let mut reader = BufReader::new(input_file).lines();

            while let Some(git_archive_path) = reader.next_line().await? {
                if let Err(err) =
                    handle_archive(&state_directory, &ci_program, &git_archive_path).await
                {
                    eprintln!("failed to handle archive: {err}");
                }
            }
        }
    };

    Ok(())
}

async fn handle_archive(
    state_directory: &PathBuf,
    ci_program: &str,
    git_archive_path: &str,
) -> anyhow::Result<()> {
    println!("Received archive {}", &git_archive_path);

    let git_archive_path = PathBuf::from(git_archive_path);

    let git_archive_name = git_archive_path
        .file_name()
        .ok_or(anyhow::anyhow!("no filename on git archive path"))?;

    // remove the extension from <name>.tar.gz
    let git_archive_name = {
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

    let run_dir = state_directory
        .join(&git_archive_name)
        .join(timestamp.to_string());

    let unpack_dir = run_dir.join("unpack");

    std::fs::create_dir_all(&run_dir).unwrap();

    let mut output_file = tokio::fs::OpenOptions::new()
        .create(true)
        .read(true)
        .write(true)
        .open(run_dir.join("output.txt"))
        .await
        .unwrap();

    let tar_gz =
        std::fs::File::open(git_archive_path.as_path()).context("failed to open git archive")?;
    let tar = GzDecoder::new(tar_gz);
    let mut archive = Archive::new(tar);

    archive
        .unpack(&unpack_dir)
        .context("failed to unpack git archive")?;

    eprintln!("working in {run_dir:?}");
    eprintln!("running {}", &ci_program);
    let mut command = tokio::process::Command::new(&ci_program);
    command.current_dir(&unpack_dir);
    command.stderr(Stdio::piped());
    command.stdout(Stdio::piped());

    if let Ok(mut child) = command.spawn() {
        let stdout = child.stdout.take().unwrap();
        let stderr = child.stderr.take().unwrap();

        let mut stdout = BufReader::new(stdout).lines();
        let mut stderr = BufReader::new(stderr).lines();

        loop {
            tokio::select! {
                out = stdout.next_line() => {
                    if let Ok(Some(out)) = out {
                        output_file.write_all(out.as_bytes()).await.unwrap();
                        output_file.write(&[b'\n']).await.unwrap();
                    } else { break; }
                },
                out = stderr.next_line() => {
                    if let Ok(Some(out)) = out {
                        output_file.write_all(out.as_bytes()).await.unwrap();
                        output_file.write(&[b'\n']).await.unwrap();
                    } else { break; }
                },
                _ = tokio::time::sleep(Duration::from_secs(60 * 30)) => {
                    eprintln!("timed out waiting for output");
                    break;
                },
            }
        }

        let status = child.wait().await?;

        eprintln!(
            "{} finished with status {}",
            ci_program,
            status.code().unwrap()
        );
    }

    tokio::fs::remove_dir_all(&unpack_dir).await?;

    Ok(())
}
