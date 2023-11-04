variables {
  db_pwd = "password"
  vpc_name = "eks-lab-vpc-module"
}

provider "aws" {
  // Due to an observed limitation when testing via the Docker image hashicorp/terraform:1.6.2,
  // variables defined in the "variables" block cannot be read in the "provider" block.
  // As the reason for this behavior is not yet understood, the "region" attribute is hard-coded
  // in the "provider" block for compatibility. 
  // Note: This limitation does not apply when testing in a devcontainer using the same Terraform version.
  region = "eu-west-3"
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