variables {
  db_pwd = "password"
  private_subnets_num = 2
}

run "get_prefix" {
  command = apply
  
  module {
    source = "./tests/random_prefix"
  }
}

run "setup" {
  command = apply

  variables {
    vpc_name = "${run.get_prefix.prefix}-test-vpc"
    eks_cluster_name = "${run.get_prefix.prefix}-ec"
    rds_subnet_group_name = "${run.get_prefix.prefix}-rds-db"
  }
}

run "confirm_num_subnets" {
  command = apply

  module {
    source = "./tests/data_dynamic"
  }

  variables {
    vpc_name = "${run.get_prefix.prefix}-test-vpc"
  }

  assert {
    condition = length(data.aws_subnet.vpc_private_subnets) == var.private_subnets_num
    error_message = "The number of private subnets is not equal to the number of private subnets specified in the variables"
  }
}