use base64::{prelude::BASE64_STANDARD, Engine};
use libsodium_sys::{
    crypto_sign_BYTES, crypto_sign_detached, crypto_sign_verify_detached, sodium_init,
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
    _ = unsafe { sodium_init() };

    let data_file = args.next().unwrap();
    let key_file = args.next().unwrap();
    let key = std::fs::read_to_string(key_file).unwrap();
    let (key_name, key_base64) = key.split_once(":").unwrap();
    let key_data = BASE64_STANDARD.decode(key_base64).unwrap();
    let data = std::fs::read_to_string(data_file).unwrap();
    let data_ = data.as_bytes();

    // let signature = sign_detached(data.as_bytes(), key_data.as_slice()).unwrap();

    let mut signature: [u8; crypto_sign_BYTES as _] = unsafe { std::mem::zeroed() };

    let mut signature_len: u64 = 0;
    let result = unsafe {
        crypto_sign_detached(
            signature.as_mut_ptr(),
            &mut signature_len,
            data_.as_ptr(),
            data_.len() as _,
            key_data.as_ptr(),
        )
    };

    if signature_len != crypto_sign_BYTES as _ {
        panic!("generated invalid signature");
    }

    if result != 0 {
        panic!("failed to sign data");
    }

    print!("{}:{}", key_name, BASE64_STANDARD.encode(signature));
}

fn verify(mut args: std::env::Args) {
    _ = unsafe { sodium_init() };

    let data_file = args.next().unwrap();
    let signature_file = args.next().unwrap();

    let mut keys = Vec::new();
    while let Some(key) = args.next() {
        let (key_name, key_base64) = key.split_once(":").unwrap();
        let key_data = BASE64_STANDARD.decode(key_base64).unwrap();
        keys.push((key_name.to_string(), key_data));
    }

    let data = std::fs::read_to_string(data_file).unwrap();
    let data_ = data.as_bytes();
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

    std::process::exit(
        unsafe {
            crypto_sign_verify_detached(
                signature_data.as_ptr(),
                data_.as_ptr(),
                data_.len() as _,
                key_data.as_ptr(),
            )
        }
        .abs(),
    );
}
