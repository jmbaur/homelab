use base64::{prelude::BASE64_STANDARD, Engine};
use sodium_sys::crypto::{
    asymmetrickey::sign::{open_detached, sign_detached},
    utils::init,
};

pub fn main() {
    let mut args = std::env::args();
    let action = args.nth(1).unwrap();

    match action.as_str() {
        "sign" => sign(args),
        "verify" => verify(args),
        _ => {
            eprintln!("unknown action {}", action);
            std::process::exit(1);
        }
    }
}

fn sign(mut args: std::env::Args) {
    init::init();

    let data_file = args.next().unwrap();
    let key_file = args.next().unwrap();
    let key = std::fs::read_to_string(key_file).unwrap();
    let (key_name, key_base64) = key.split_once(":").unwrap();
    let key_data = BASE64_STANDARD.decode(key_base64).unwrap();
    let data = std::fs::read_to_string(data_file).unwrap();
    let signature = sign_detached(data.as_bytes(), key_data.as_slice()).unwrap();

    print!("{}:{}", key_name, BASE64_STANDARD.encode(signature));
}

fn verify(mut args: std::env::Args) {
    init::init();

    let data_file = args.next().unwrap();
    let signature_file = args.next().unwrap();

    let mut keys = Vec::new();
    while let Some(key) = args.next() {
        let (key_name, key_base64) = key.split_once(":").unwrap();
        let key_data = BASE64_STANDARD.decode(key_base64).unwrap();
        keys.push((key_name.to_string(), key_data));
    }

    let data = std::fs::read_to_string(data_file).unwrap();
    let signature = std::fs::read_to_string(signature_file).unwrap();
    let (signature_key_name, signature_base64) = signature.split_once(":").unwrap();
    let signature_data = BASE64_STANDARD.decode(signature_base64).unwrap();

    let key_data = keys
        .iter()
        .find_map(|(key_name, key_data)| {
            if key_name == signature_key_name {
                Some(key_data)
            } else {
                None
            }
        })
        .unwrap();

    std::process::exit(open_detached(data.as_bytes(), signature_data.as_slice(), key_data).abs());
}
