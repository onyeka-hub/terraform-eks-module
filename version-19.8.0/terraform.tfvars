################################################################################
# vpc
################################################################################
region = "us-east-2"

name = "onyi"

vpc_cidr = "10.0.0.0/16"

vpc_tags = {
  Name = "onyi-vpc"
}

public_route_table_tags = {
  Name = "onyi-public-route-table"
}

private_route_table_tags = {
  Name = "onyi-private-route-table"
}

nat_gateway_tags = {
  Name = "onyi-nat-gateway"
}

nat_eip_tags = {
  Name = "onyi-elastic-ip"
}

public_subnet_names = ["onyi-public-subnet-1", "onyi-public-subnet-2"]

private_subnet_names = ["onyi-private-subnet-1", "onyi-private-subnet-2"]


