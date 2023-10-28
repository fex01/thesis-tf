variables {
  db_pwd = "password"
  vpc_name = "eks-lab-vpc-module"
  ownerId = "140191150128"
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

