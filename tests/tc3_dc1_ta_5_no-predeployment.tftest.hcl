variables {
  db_pwd_l7 = "1234567"
  db_pwd_l8 = "12345678"
  db_pwd_l9 = "123456789"
}

// -----------------------------------------------------------------------------
// NOTE ON TEST CASE DESIGN
// -----------------------------------------------------------------------------
//
// Due to the unique constraints of this test case, it is not feasible to run 
// tests against existing infrastructure without modifications. However, this 
// test case does deploy into the common test environment rather than an 
// isolated one.
//
// To coexist harmoniously in the shared environment, a concept of "separation by 
// namespace" is employed. Specifically, key resources generated during the test 
// are prefixed with a random identifier. This allows for resource isolation on 
// a per-test basis, mitigating the risk of conflicts or collisions with other 
// ongoing tests or resources.
//
// -----------------------------------------------------------------------------

run "get_prefix" {
  command = apply
  
  module {
    source = "./tests/random_prefix"
  }
}

// -----------------------------------------------------------------------------
// NOTE ON TESTING LIMITATIONS
// -----------------------------------------------------------------------------
//
// 'terraform test' does not support expected failure
// testing for dynamic test cases. Due to this limitation, dynamic tests that 
// are expected to fail (i.e., testing invalid or erroneous variable values) 
// are intentionally skipped in the testing process.
//
// -----------------------------------------------------------------------------

// run "db_pwd_l7" {
//   command = apply

//   variables {
//     db_pwd = var.db_pwd_l7
//     vpc_name = "${run.get_prefix.prefix}-test-vpc"
//     eks_cluster_name = "${run.get_prefix.prefix}-ec"
//     rds_subnet_group_name = "${run.get_prefix.prefix}-rds-db"
// //   }

//   expect_failures = [
//     var.db_pwd,
//   ]
// }

run "db_pwd_l8" {
  command = apply

  variables {
    db_pwd = var.db_pwd_l8
    vpc_name = "${run.get_prefix.prefix}-test-vpc"
    eks_cluster_name = "${run.get_prefix.prefix}-ec"
    rds_subnet_group_name = "${run.get_prefix.prefix}-rds-db"
  }
}

run "db_pwd_l9" {
  command = apply

  variables {
    db_pwd = var.db_pwd_l9
    vpc_name = "${run.get_prefix.prefix}-test-vpc"
    eks_cluster_name = "${run.get_prefix.prefix}-ec"
    rds_subnet_group_name = "${run.get_prefix.prefix}-rds-db"
  }
}