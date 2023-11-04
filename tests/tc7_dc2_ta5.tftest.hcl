variables {
  db_pwd = "password"
  vpc_name = "eks-lab-vpc-module"
  ownerId = "140191150128"
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

