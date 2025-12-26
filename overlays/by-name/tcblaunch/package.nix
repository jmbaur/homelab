{
  lib,
  stdenv,
  fetchurl,
}:

assert (lib.assertMsg stdenv.hostPlatform.isAarch64 "tcblaunch only fetched for arm64 right now");
fetchurl {
  url = "https://vsblobprodscussu5shard90.blob.core.windows.net/b-4712e0edc5a240eabf23330d7df68e77/4F9B2982937F4B7FC56DBBD667745F4F0FF8FA71561CD8684A2902159CA3FC0100.blob?sv=2019-07-07&sr=b&sig=pe6b74jGunCMhOHfkQQNll5rth0zLyeAAToScISlaGs%3D&skoid=4866d8d7-57cb-4216-997d-bade18bdbe68&sktid=33e01921-4d64-4f8c-a055-5bdaffd5e33d&skt=2025-12-26T03%3A45%3A26Z&ske=2025-12-28T04%3A45%3A26Z&sks=b&skv=2019-07-07&se=2025-12-27T06%3A18%3A38Z&sp=r&rscl=x-e2eid-fac63bd0-d5f74adf-bb992798-5cff52f2-session-3a8a353c-4b2c41d9-a9a9d47f-0e3d286b"; # TODO(jared): no idea if this is permalink-ish
  hash = "sha256-XfzQJTtu6ZSZqzPKwiHoqc6kfz/fbU4R3pqfPEdw0D0=";
}
