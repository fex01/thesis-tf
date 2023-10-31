# Quantitative Cost Assessment of IaC Testing: Proof of Concept Implementation

**WIP: This repository is a work in progress.**

This repository is a work in progress and part of ongoing research for a master thesis scheduled for completion in February 2024.
Up until that point, the project may undergo significant changes and updates, including its documentation which is currently rudimentary, consisting of placeholders or still to-do.
Nonetheless, feedback is highly encouraged, particularly concerning different test approaches and test case implementations.

---

## Introduction

[Placeholder]

This repository contains the proof of concept implementation for the master thesis titled "Quantitative Cost Assessment of IaC Testing". The purpose of this implementation is to gather empirical data that serves to quantitatively assess the costs associated with testing Infrastructure as Code (IaC) configurations. 

---

## Setup

For setting up and running this PoC, please refer to the separate repository [thesis-ws](https://github.com/fex01/thesis-ws). This repository serves as a supporting workspace and contains essential guides and tooling required for the setup and execution of the PoC.

The separation of these repositories is intended to facilitate streamlined testing. By isolating the executable code, the test pipeline can directly check out only the components necessary for execution, thereby simplifying the testing process.

---

## Test Cases

In this PoC, the implemented test cases are organized according to the Testing Approach (TA) and Defect Category (DC) they target. The objective is to validate the Test Coverage Matrix proposed in our thesis by implementing test cases for each corresponding DC/TA match, thereby demonstrating its practical applicability.

### Test Coverage Matrix

|                     | TA1 (Formatting) | TA2 (Linting) | TA3 (PaC) | TA4 (Unit) | TA5 (Integration) | TA6 (E2E) |
|---------------------|------------------|---------------|-----------|------------|-------------------|-----------|
| DC1 Conditional     |                  |               |           | 🟢         | 🟢                |           |
| DC2 Configuration   |                  |               |           | 🟢         | 🟢                 |            |
| DC3 Dependency      |                  |               |           | 🔵         | 🔵                | 🔵         |
| DC4 Documentation   |                  |               |           | 🟡         |                   |           |
| DC5 Idempotency     |                  |               |           |            | 🟢                | 🟢         |
| DC6 Security        |                  |               | 🔵        | 🟡         | 🟡                | 🔵         |
| DC7 Service         |                  |               |           |            |                   | 🟢         |
| DC8 Syntax          | 🔵               | 🔵           |           |            |                   |           |

- 🟢 = Fully covered
- 🔵 = Partly covered
- 🟡 = Minimal coverage

### Specific Test Cases

Overlapping test cases exist across different testing approaches for the purpose of comparative analysis. For instance, the test case validating that _passwords are flagged as sensitive_ is common between Policy as Code (TA3) and Static Unit Testing (TA4). Similarly, tests for _variable validation_ overlap between Static Unit Testing (TA4) and Dynamic Integration Testing (TA5).

#### Tool-Driven Testing (TA1, TA2)

For Formatting (TA1) and Linting (TA2), no specific test cases are needed as they are tool-driven, primarily focusing on Syntax (DC8). The tools used for these approaches are `terraform fmt` and `terraform validate`, respectively.

#### Policy as Code (TA3)

Policy as Code (TA3) addresses Security (DC6) with a custom policy to ensure that [passwords are flagged as sensitive](https://github.com/fex01/thesis-tf/blob/main/tfsec/dc6_tc1_ta3_tfchecks.yaml). The tool used for this approach is `tfsec`.

#### Static Unit Testing (TA4)

Various defect categories were addressed - initially using terraform test and supplementing with pytest where required.

- Conditional Logic (DC1) is covered through:
  - [Variable validation](https://github.com/fex01/thesis-tf/blob/main/tests/dc1_tc1_ta4.tftest.hcl) (`terraform test`)
  - [For loops](https://github.com/fex01/thesis-tf/blob/main/tests/dc1_tc2_ta4.tftest.hcl) (`terraform test`)
- Configuration Data (DC2) is verified with:
  - [blast radius check](https://github.com/fex01/thesis-tf/blob/main/tests/dc2_tc1_ta4.tftest.hcl) (`terraform test`)
  - [Validate configuration expectation](https://github.com/fex01/thesis-tf/blob/main/pytest/test_dc2_tc2_ta4.py) (pytest)
- Dependencies (DC3):
  - [Module is locally available](https://github.com/fex01/thesis-tf/blob/main/pytest/test_dc3_tc1_ta4.py) (pytest)
- Documentation (DC4):
  - [Readme exists and has an Acknowledgment section](https://github.com/fex01/thesis-tf/blob/main/pytest/test_dc4_tc1_ta4.py) (pytest)
- Security (DC6): [Passwords are flagged as sensitive](https://github.com/fex01/thesis-tf/blob/main/pytest/test_dc6_tc1_ta4.py) (pytest)

#### Dynamic Integration Testing (TA5)

- Test cases for Integration Testing (TA5) primarily employ `terraform test` and are supplemented with Terratest where necessary. They are designed to cover:

- Conditional Logic (DC1):
  - [Variable validation](https://github.com/fex01/thesis-tf/blob/main/tests/dc1_tc1_ta5.tftest.hcl) (`terraform test`)
  - [For loops](https://github.com/fex01/thesis-tf/blob/main/tests/dc1_tc2_ta5.tftest.hcl) (`terraform test`)
- Configuration Data (DC2):
  - [Blast radius check](https://github.com/fex01/thesis-tf/blob/main/tests/dc2_tc1_ta5.tftest.hcl) (`terraform test`)
- Dependencies (DC3):
  - [Module resources got deployed](https://github.com/fex01/thesis-tf/blob/main/tests/dc3_tc1_ta5.tftest.hcl) (`terraform test`)
- Idempotency (DC5):
  - [Terratest Idempotency Test](https://github.com/fex01/thesis-tf/blob/main/terratest/dc5_tc1_ta5_test.go) (Terratest)

As of now, no test cases (TCs) have been designed or implemented for End-2-End Testing (TA6). This category might be out of scope for this thesis. 
However, it's worth noting that the main difference between Integration Testing (TA5) and End-2-End Testing (TA6) lies less in the tools employed and more in the perspective of the testing. 
Unlike other testing approaches that concentrate on technical requirements, E2E testing is designed to verify the product's usability from a customer's standpoint. 
Achieving this would require the development of user stories for our Configuration Under Test (CUT).

To illustrate, consider the following examples for different Defect Categories (DCs) in E2E Testing:

- DC3 (Dependency): A user story could involve different components interacting together. In this scenario, the focus would not be on the individual components themselves but on the overall user experience. Nevertheless, if the components are poorly integrated, the test case would fail.
- DC5 (Idempotency): An E2E test case might aim to ensure that customer usability is not affected during system rollouts, taking steps to prevent data corruption or loss.
- DC6 (Security): Security in the context of E2E tests could mean ensuring that customers cannot access restricted internal portals, offering a different dimension to security testing than other test approaches.

---

## Acknowledgment

The "Configuration under Test" (CUT), which is the Terraform configuration utilized in this implementation, was originally developed by Mattia Caracciolo for his thesis titled "Policy as Code, how to automate cloud compliance verification with open-source tools".
Mattia did not publish his code but graciously permitted us to adapt and publish the code for the purpose of this thesis.
We extend our sincere thanks to Mattia for his contribution.

---

For any questions or concerns, please raise an issue in the repository or contact the author directly.

Thank you for taking an interest in this research.