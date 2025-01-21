use base64::{prelude::BASE64_STANDARD, Engine};
use sodium_sys::crypto::{
    asymmetrickey::sign::{open_detached, sign_detached},
    utils::init,
};

pub fn main() {
    let action = std::env::args().nth(1).unwrap();

    match action.as_str() {
        "sign" => sign(),
        "verify" => verify(),
        _ => eprintln!("unknown action {}", action),
    }
}

fn sign() {
    init::init();

    let key_file = std::env::args().nth(2).unwrap();
    let data_file = std::env::args().nth(3).unwrap();
    let key = std::fs::read_to_string(key_file).unwrap();
    let (key_name, key_base64) = key.split_once(":").unwrap();
    let key_data = BASE64_STANDARD.decode(key_base64).unwrap();
    let data = std::fs::read_to_string(data_file).unwrap();
    let signature = sign_detached(data.as_bytes(), key_data.as_slice()).unwrap();

    print!("{}:{}", key_name, BASE64_STANDARD.encode(signature));
}

fn verify() {
    init::init();

    let key_file = std::env::args().nth(2).unwrap();
    let data_file = std::env::args().nth(3).unwrap();
    let signature_file = std::env::args().nth(4).unwrap();
    let key = std::fs::read_to_string(key_file).unwrap();
    let (_key_name, key_base64) = key.split_once(":").unwrap();
    let key_data = BASE64_STANDARD.decode(key_base64).unwrap();
    let data = std::fs::read_to_string(data_file).unwrap();
    let signature = std::fs::read_to_string(signature_file).unwrap();
    let (_signature_key_name, signature_base64) = signature.split_once(":").unwrap();
    let signature_data = BASE64_STANDARD.decode(signature_base64).unwrap();

    std::process::exit(open_detached(
        data.as_bytes(),
        signature_data.as_slice(),
        key_data.as_slice(),
    ));
}
