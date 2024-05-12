################################################################################
# vpc
################################################################################
region = "us-east-2"

name = "onyeka"

vpc_cidr = "10.0.0.0/16"

vpc_tags = {
  Name = "onyeka-vpc"
}

public_route_table_tags = {
  Name = "onyeka-public-route-table"
}

private_route_table_tags = {
  Name = "onyeka-private-route-table"
}

nat_gateway_tags = {
  Name = "onyeka-nat-gateway"
}

nat_eip_tags = {
  Name = "onyeka-elastic-ip"
}

public_subnet_names = ["onyeka-public-subnet-1", "onyeka-public-subnet-2"]

private_subnet_names = ["onyeka-private-subnet-1", "onyeka-private-subnet-2"]


