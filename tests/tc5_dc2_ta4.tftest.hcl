variables {
  db_pwd = "password"
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

run "confirm_deployment_credentials" {
  command = plan

  module {
    source = "./tests/data_static"
  }

  assert {
    condition = data.aws_caller_identity.current.account_id == var.ownerId
    error_message = "Test deployments should be facilitated with account ID: ${var.ownerId}, but configured account ID is: ${data.aws_caller_identity.current.account_id}"
  }
}
