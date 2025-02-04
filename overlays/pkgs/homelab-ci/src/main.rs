use futures::StreamExt;

#[tokio::main]
async fn main() -> Result<(), async_nats::Error> {
    let mut args = std::env::args();

    let _argv0 = args.next().expect("missing argv0");
    let ci_program = args.next().expect("missing CI program");

    let client = async_nats::connect("[::]:4222").await?;
    let mut subscriber = client.subscribe("ci").await?;

    while let Some(message) = subscriber.next().await {
        println!("Received message {:?}", message);

        let mut command = tokio::process::Command::new(&ci_program);
        command.current_dir("");

        if let Ok(mut child) = command.spawn() {
            _ = child.wait();
        }
    }

    Ok(())
}
