import json
import ipaddress

NETWORK_RANGE = ipaddress.ip_network('10.0.0.0/16')

def test_dc2_tc2_ta4():
    """
    Confirm configuration expectations to avoid conflicting configurations.
    Ensures that vpc subnets are in the range NETWORK_RANGE.
    """

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
