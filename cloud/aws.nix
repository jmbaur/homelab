{ config, ... }: {
  resource.aws_vpc.homelab = {
    cidr_block = "10.0.0.0/16";
    assign_generated_ipv6_cidr_block = true;

    tags = {
      Name = "homelab";
    };
  };

  resource.aws_subnet.homelab-main = {
    vpc_id = "\${aws_vpc.homelab.id}";
    cidr_block = "\${cidrsubnet(aws_vpc.homelab.cidr_block, 4, 1)}";
    map_public_ip_on_launch = true;

    ipv6_cidr_block = "\${cidrsubnet(aws_vpc.homelab.ipv6_cidr_block, 8, 1)}";
    assign_ipv6_address_on_creation = true;

    tags = {
      Name = "main";
    };
  };

  resource.aws_internet_gateway.homelab = {
    vpc_id = "\${aws_vpc.homelab.id}";
  };

  resource.aws_default_route_table.homelab = {
    default_route_table_id = "\${aws_vpc.homelab.default_route_table_id}";
    route = map
      (args: {
        cidr_block = null;
        core_network_arn = null;
        destination_prefix_list_id = null;
        egress_only_gateway_id = null;
        instance_id = null;
        ipv6_cidr_block = null;
        nat_gateway_id = null;
        network_interface_id = null;
        transit_gateway_id = null;
        vpc_endpoint_id = null;
        vpc_peering_connection_id = null;
      }
      // args) [
      {
        foo = "bar";
        cidr_block = "0.0.0.0/0";
        gateway_id = "\${aws_internet_gateway.homelab.id}";
      }
      {
        ipv6_cidr_block = "::/0";
        gateway_id = "\${aws_internet_gateway.homelab.id}";
      }
    ];
  };

  resource.aws_route_table_association.homelab = {
    subnet_id = "\${aws_subnet.homelab-main.id}";
    route_table_id = "\${aws_default_route_table.homelab.id}";
  };

  resource.aws_security_group.homelab = {
    name = "allow everything";
    vpc_id = "\${aws_vpc.homelab.id}";
    ingress = map
      (args: {
        description = null;
        cidr_blocks = null;
        ipv6_cidr_blocks = null;
        prefix_list_ids = null;
        security_groups = null;
        self = null;
      } // args) [
      {
        from_port = 0;
        to_port = 0;
        protocol = -1;
        cidr_blocks = [ "0.0.0.0/0" ];
      }
      {
        from_port = 0;
        to_port = 0;
        protocol = "-1";
        ipv6_cidr_blocks = [ "::/0" ];
      }
    ];

    egress = map
      (args: {
        description = null;
        cidr_blocks = null;
        ipv6_cidr_blocks = null;
        prefix_list_ids = null;
        security_groups = null;
        self = null;
      } // args) [
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

  resource.aws_key_pair = {
    default = {
      key_name = "default";
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIKec4LEGZ0MxYx39lJh31hHDZCxuloLyzs1mLtMhiwR";
    };
  };

  resource.aws_instance.homelab-web = {
    ami = "ami-0f96be48071c13ab2";
    key_name = "default";
    instance_type = "t4g.micro";
    subnet_id = "\${aws_subnet.homelab-main.id}";
    ipv6_address_count = 1;
    vpc_security_group_ids = [ "\${aws_security_group.homelab.id}" ];
    root_block_device = {
      delete_on_termination = true;
      volume_size = 10; # GiB
    };
    tags = {
      Name = "homelab-web";
    };
    depends_on = [ "aws_internet_gateway.homelab" ];
  };
}
