variables {
  db_pwd = "password"
  vpc_name = "eks-lab-vpc-module"
}

// run "setup" {
//   command = apply
// }

run "confirm_vpc_deployment" {
  command = apply

  module {
    source = "./tests/data_dynamic"
  }

  assert {
    condition = data.aws_vpc.vpc.id != ""
    error_message = "VPC ${var.vpc_name} not deployed"
  }
}