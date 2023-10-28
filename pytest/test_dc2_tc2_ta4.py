import os
import json
import ipaddress

NETWORK_RANGE = ipaddress.ip_network('11.0.0.0/16')
JSON_PLAN = "plan.json"

def test_dc2_tc2_ta4():
    """
    Testing for configuration defects.

    Confirm configuration expectations to avoid conflicting configurations.
    Ensures that vpc subnets are in the range NETWORK_RANGE.
    """

    # Check execution context
    if '.terraform' not in os.listdir('.'):
        current_path = os.getcwd()
        raise Exception(
            f"The test expects to be run in the context of the Terraform "
            f"configuration folder. Current execution context is {current_path}."
        )
    
    # Check if plan file exists in the current directory
    if not os.path.isfile(JSON_PLAN):
        raise Exception(
            f"Expected json plan file {JSON_PLAN} to exist in the current "
            f"directory, but it does not."
        )

    # Load the plan.json content into a Python dictionary
    with open('plan.json', 'r') as f:
        plan_data = json.load(f)

    # Recursive function to check each dict element for an 'address' attribute
    def check_resources(d):
        if isinstance(d, dict):
            address_value = d.get('address')
            if address_value and isinstance(address_value, str) and "module.vpc.aws_subnet." in address_value:
                cidr_block = d.get('values', {}).get('cidr_block')
                if cidr_block:
                    assert ipaddress.ip_network(cidr_block).subnet_of(NETWORK_RANGE), (
                        f"The CIDR block {cidr_block} of resource {address_value} "
                        "is not within the range of 10.0.0.0/16."
                    )
            for k in d:
                check_resources(d[k])
        elif isinstance(d, list):
            for item in d:
                check_resources(item)

    # Start the check
    check_resources(plan_data)
