variables {
  db_pwd = "password"
  ownerId = "140191150128"
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

