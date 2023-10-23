variables {
  db_pwd = "password"
  private_subnets_num = 2
}

run "confirm_num_subnets" {
  command = plan

  assert {
    condition = length(module.vpc.private_subnets) == var.private_subnets_num
    error_message = "The number of private subnets is not equal to the number of private subnets specified in the variables"
  }
}