{ ... }: {
  # Versioning of these providers is provided by Nix.
  terraform.required_providers = {
    aws.source = "registry.terraform.io/hashicorp/aws";
    cloudflare.source = "registry.terraform.io/cloudflare/cloudflare";
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
