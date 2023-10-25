package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func Test_dc5_tc1_ta5(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.

	dbPwd := "password"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "../",
		NoColor: true,

		Vars: map[string]interface{}{
			"db_pwd": dbPwd,
		},
	})

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.ApplyAndIdempotent(t, terraformOptions)
}