variables {
  db_pwd = "password"
  private_subnets_num = 2
  vpc_name = "eks-lab-vpc-module"
}

// run "setup" {
//   command = apply
// }

run "confirm_num_subnets" {
  command = apply

  module {
    source = "./tests/data_dynamic"
  }

  assert {
    condition = length(data.aws_subnet.vpc_private_subnets) == var.private_subnets_num
    error_message = "The number of private subnets is not equal to the number of private subnets specified in the variables"
  }
}