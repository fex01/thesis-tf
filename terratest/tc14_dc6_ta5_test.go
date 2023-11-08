package test

import (
	"net"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Testing for security defects.
//
// Test verifies that the DNS resolution for an RDS instance
// adheres to security best practices by only resolving to private IP addresses.
// This test ensures the RDS instance is not publicly accessible, mitigating the risk
// of exposing sensitive data or attack vectors to the outside world.
func Test_tc14_dc6_ta5(t *testing.T) {

	dbPwd := os.Getenv("DB_PWD")

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
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

	// Initialize and apply the Terraform code with the Terraform options configured.
	terraform.Apply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable.
	rdsInstanceAddress := terraform.Output(t, terraformOptions, "rds_instance_address")

	// Resolve the RDS instance address to check if it's a private IP.
	ips, err := net.LookupIP(rdsInstanceAddress)
	assert.NoError(t, err)

	// Assert that the resolved IP is a private IP.
	for _, ip := range ips {
			assert.True(t, isPrivateIP(ip), "The IP address must be private.")
	}
}

// isPrivateIP checks if the given IP address is in a private range.
func isPrivateIP(ip net.IP) bool {
	// Private IP ranges are defined in RFC 1918 for IPv4 and RFC 4193 for IPv6.
	// https://en.wikipedia.org/wiki/Private_network
	for _, network := range []string{
			"10.0.0.0/8",       // 10.0.0.0 - 10.255.255.255
			"172.16.0.0/12",    // 172.16.0.0 - 172.31.255.255
			"192.168.0.0/16",   // 192.168.0.0 - 192.168.255.255
			"fd00::/8",       	// fd00:: - fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
	} {
			_, subnet, _ := net.ParseCIDR(network)
			if subnet.Contains(ip) {
					return true
			}
	}
	return false
}
