variables {
  db_pwd_l7 = "1234567"
  db_pwd_l8 = "12345678"
  db_pwd_l9 = "123456789"
}

run "db_pwd_l9" {
  command = apply

  variables {
    db_pwd = var.db_pwd_l9
  }
}