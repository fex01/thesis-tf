variables {
  db_pwd = "password"
  vpc_name = "eks-lab-vpc-module"
  ownerId = "140191150128"
}

// run "setup" {
//   command = apply
// }

run "confirm_deployment_credentials" {
  command = apply

  module {
    source = "./tests/data_dynamic"
  }

  assert {
    condition = data.aws_vpc.vpc.owner_id == var.ownerId
    error_message = "Test deployments should be facilitated with account ID: ${var.ownerId}, but configured account ID is: ${data.aws_vpc.vpc.owner_id}"
  }
}

