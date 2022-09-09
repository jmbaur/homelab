{ ... }: {
  # Versioning of these providers is provided by Nix.
  terraform.required_providers = {
    aws.source = "hashicorp/aws";
    cloudflare.source = "cloudflare/cloudflare";
  };

  provider = {
    aws = {
      region = "us-west-1";
    };
    cloudflare = { };
  };

  imports = [
    ./aws.nix
    ./cloudflare.nix
  ];
}
