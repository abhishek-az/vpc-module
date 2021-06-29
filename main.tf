provider aws {
 access_key = var.access_key
 secret_key = var.secret_key
 region = var.region
}

resource aws_vpc k8s_vpc {
 cidr_block = var.vpc_cidr_block
 enable_dns_hostnames=true

 tags = {
  Name = var.vpc_name
 }
}


resource aws_subnet k8s_pub_subnet {
 count = var.pub_subnet_count
 vpc_id = aws_vpc.k8s_vpc.id
 map_public_ip_on_launch = true
 cidr_block = var.pub_subnet_cidr[count.index]
 availability_zone = var.aws_availabilty_zones[count.index]
 tags = {
  Name = format("${var.pub_subnet_name}-%d", count.index + 1 )
 }
}

resource aws_subnet k8s_prv_subnet {
 count = var.prv_subnet_count
 vpc_id = aws_vpc.k8s_vpc.id
 cidr_block = var.prv_subnet_cidr[count.index]
 availability_zone = var.aws_availabilty_zones[count.index]
 tags = {
  Name = format("${var.prv_subnet_name}-%d", count.index + 1 )
 }
}

resource aws_internet_gateway k8s_igw {
 vpc_id = aws_vpc.k8s_vpc.id
 
 tags = { 
  Name = var.igw_name
 }
}

resource aws_route_table k8s_public_rt {
 vpc_id = aws_vpc.k8s_vpc.id
 
 tags = { 
  Name = var.pub_rt_name
 }
 
 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.k8s_igw.id
 }
}

resource aws_route_table_association k8s_pub_route_association {
 count = length(aws_subnet.k8s_pub_subnet)
 subnet_id = aws_subnet.k8s_pub_subnet.*.id[count.index]
 route_table_id = aws_route_table.k8s_public_rt.id
}

resource aws_eip byoip-ip {
  vpc              = true
}

resource aws_nat_gateway example {
  count = 1
  allocation_id = aws_eip.byoip-ip.id
  subnet_id     = aws_subnet.k8s_pub_subnet.*.id[count.index]
  tags = {
    Name = var.nat_gateway
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.k8s_igw, aws_eip.byoip-ip]
}
