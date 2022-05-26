{ config, lib, ... }: {
  # Versioning of these providers is provided by Nix.
  terraform.required_providers = {
    aws.source = "hashicorp/aws";
    cloudflare.source = "cloudflare/cloudflare";
    github.source = "integrations/github";
  };

  provider = {
    aws.region = "us-west-2";
    cloudflare = { };
    github = { };
  };

  resource = {
    github_repository_webhook.homelab = {
      repository = "homelab";
      configuration = {
        content_type = "json";
        url = "TODO";
        secret = "TODO";
      };
      active = true;
      events = [ "push" ];
    };

    aws_vpc.vpc = {
      cidr_block = "172.16.0.0/16";
      assign_generated_ipv6_cidr_block = true;
    };

    aws_subnet.subnet = {
      vpc_id = "\${aws_vpc.vpc.id}";
      cidr_block = "\${cidrsubnet(aws_vpc.vpc.cidr_block, 4, 1)}";
      map_public_ip_on_launch = true;
      ipv6_cidr_block = "\${cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, 1)}";
      assign_ipv6_address_on_creation = true;
    };

    aws_internet_gateway.gateway = {
      vpc_id = "\${aws_vpc.eu-central-1.id}";
    };

    aws_default_route_table.route_table = {
      default_route_table_id = "\${aws_vpc.vpc.default_route_table_id}";
      route = [
        {
          cidr_block = "0.0.0.0/0";
          gateway_id = "\${aws_internet_gateway.gateway.id}";
        }
        {
          ipv6_cidr_block = "::/0";
          gateway_id = "\${aws_internet_gateway.gateway.id}";
        }
      ];
    };

    aws_route_table_association.route_table_association = {
      subnet_id = "\${aws_subnet.subnet.id}";
      route_table_id = "\${aws_default_route_table.route_table.id}";
    };

    aws_security_group.security_group = {
      name = "ssh_and_any_egress";
      vpc_id = "\${aws_vpc.vpc.id}";
      ingress = [
        {
          from_port = 22;
          to_port = 22;
          protocol = "tcp";
          cidr_blocks = [ "0.0.0.0/0" ];
        }
        {
          from_port = 0;
          to_port = 0;
          protocol = "-1";
          ipv6_cidr_blocks = [ "::/0" ];
        }
      ];

      egress = [
        {
          from_port = 0;
          to_port = 0;
          protocol = "-1";
          cidr_blocks = [ "0.0.0.0/0" ];
        }
        {
          from_port = 0;
          to_port = 0;
          protocol = "-1";
          ipv6_cidr_blocks = [ "::/0" ];
        }
      ];
    };

    # aws_key_pair.jmbaur = {
    #   key_name = "jmbaur";
    #   public_key = "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBD1B20XifI8PkPylgWlTaPUttRqeseqI0cwjaHH4jKItEhX8i5+4PcbtJAaJAOnFe28E8OMyxxm5Tl3POkdC8WsAAAAEc3NoOg==";
    # };

    aws_instance.vps = {
      ami = "ami-0a6892c61d85774db";
      instance_type = "t4g.nano"; # TODO(jared): maybe switch to t4g.micro
      # key_name = config.resource.aws_key_pair.jmbaur.key_name;
      associate_public_ip_address = true;
      ipv6_address_count = 1;
      vpc_security_group_ids = [ "\${aws_security_group.security_group.id}" ];
      user_data = ''
        #!/usr/bin/env bash
        mkdir -p /root/.ssh
        cat > /root/.ssh/authorized_keys << EOF
        ${builtins.readFile (import ./data/jmbaur-ssh-keys.nix)}
        EOF
      '';
      subnet_id = "\${aws_subnet.subnet.id}";
    };
  };
}
