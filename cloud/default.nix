{ ... }: {
  # Versioning of these providers is provided by Nix.
  terraform.required_providers = {
    aws.source = "registry.terraform.io/hashicorp/aws";
    cloudflare.source = "registry.terraform.io/cloudflare/cloudflare";
    sops.source = "registry.terraform.io/carlpett/sops";
  };

  provider = {
    aws = { };
    cloudflare = { };
    sops = { };
  };

  imports = [
    ./aws.nix
    ./cloudflare.nix
  ];
}
