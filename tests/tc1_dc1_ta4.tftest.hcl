variables {
  db_pwd_l7 = "1234567"
  db_pwd_l8 = "12345678"
  db_pwd_l9 = "123456789"
}

run "db_pwd_l7" {
  command = plan

  variables {
    db_pwd = var.db_pwd_l7
  }

  expect_failures = [
    var.db_pwd,
  ]
}

run "db_pwd_l8" {
  command = plan

  variables {
    db_pwd = var.db_pwd_l8
  }
}

run "db_pwd_l9" {
  command = plan

  variables {
    db_pwd = var.db_pwd_l9
  }
}