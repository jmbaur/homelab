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
}
