variables {
  db_pwd = "password"
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