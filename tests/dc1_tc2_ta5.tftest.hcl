variables {
  db_pwd = "password"
  private_subnets_num = 2
  vpc_name = "eks-lab-vpc-module"
  region = "eu-west-3"
}

provider "aws" {
  region = var.region
}

// -----------------------------------------------------------------------------
// NOTE ON INFRASTRUCTURE MANAGEMENT
// -----------------------------------------------------------------------------
//
// Infrastructure deployment and destruction are managed separately from the 
// test cases. This design enables multiple tests to run against the same 
// deployed infrastructure, thus minimizing the number of deployments required. 
// This approach aims to optimize resource utilization and reduce execution time.
//
// To run tests independently, a setup run must be included. This can be achieved 
// by adding a 'setup' run block with the 'apply' command, as shown below:
//
// run "setup" {
//   command = "apply"
// }
//
// -----------------------------------------------------------------------------


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