pipeline {
    agent any

    parameters {
        booleanParam defaultValue: false, name: 'dynamic_testing', description: 'Run dynamic tests'
        booleanParam defaultValue: false, name: 'nuke', description: 'Use only in test env - highly destructive!'
        string defaultValue: '1.6.2', name: 'terraform_version', description: 'Terraform version to use'
        string defaultValue: '0.10.30', name: 'infracost_version', description: 'Infracost version to use'
        string defaultValue: '1.28', name: 'tfsec_version', description: 'tfsec version to use'
        string defaultValue: '0.3.4-rc.2', name: 'pytest_version', description: 'databricksdocs/pytest image version to use'
        string defaultValue: '0.29.0', name: 'terratest_version', description: 'terratest version to use'
        string defaultValue: '0.32.0', name: 'cloud_nuke_version', description: 'cloud-nuke version to use'
        string defaultValue: '2.13.32', name: 'aws_cli_version', description: 'AWS CLI version to use'
    }
    environment {
        CSV_FILE = 'measurements.csv'
        REGION = 'eu-west-3'
        PLAN_JSON = 'plan.json'
        PLAN_TXT = 'plan.txt'
        INFRACOST_JSON = 'infracost.json'
    }

    stages {
        stage("Initialize") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image "hashicorp/terraform:${params.terraform_version}"
                    reuseNode true
                }
            }
            steps {
                echo "${params}"
                sh "terraform init -no-color"
            }
        }
        stage("Tool-Driven: TA1 Formatting") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image "hashicorp/terraform:${params.terraform_version}"
                    reuseNode true
                }
            }
            environment {
                DEFECT_CATEGORY = '8'
                TEST_APPROACH = '1'
                TEST_COMMAND = 'terraform fmt --check --diff -no-color'
            }
            steps {
                sh """scripts/run_test.sh \\
                    --build-number ${BUILD_NUMBER} \\
                    --defect-category ${DEFECT_CATEGORY} \\
                    --test-approach ${TEST_APPROACH} \\
                    --test-command '${TEST_COMMAND}' \\
                    --csv-file ${CSV_FILE}"""
            }
        }
        stage("Tool-Driven TA2 Linting") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image "hashicorp/terraform:${params.terraform_version}"
                    reuseNode true
                }
            }
            environment {
                DEFECT_CATEGORY = '8'
                TEST_APPROACH = '2'
                TEST_COMMAND = 'terraform validate -no-color'
            }
            steps {
                sh """scripts/run_test.sh \\
                    --build-number ${BUILD_NUMBER} \\
                    --defect-category '${DEFECT_CATEGORY}' \\
                    --test-approach ${TEST_APPROACH} \\
                    --test-command '${TEST_COMMAND}' \\
                    --csv-file ${CSV_FILE}"""
            }
        }
        stage("Plan") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image "hashicorp/terraform:${params.terraform_version}"
                    reuseNode true
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY"),
                     usernamePassword(credentialsId: "terraform-db-credentials", usernameVariable: "DB_USR", passwordVariable: "DB_PWD") ]) {
                    sh "terraform plan -out plan.tfplan -refresh=false -no-color -var=db_pwd=\$DB_PWD > /dev/null"
                }
                // Perform a 'terraform show -json' to generate a JSON file for static testing.
                // The JSON format offers structured data but does not honor sensitivity flags.
                sh "terraform show -json plan.tfplan > ${PLAN_JSON}"
                // Perform a 'terraform show' to generate a text file for static testing.
                // Unlike the JSON format, the text file honors sensitivity flags.
                sh "terraform show -no-color plan.tfplan > ${PLAN_TXT}"
            }
        }
        stage('Cost Breakdown') {
            agent{
                dockerfile{
                    dir 'tools'
                    filename 'DOCKERFILE'
                    additionalBuildArgs "--build-arg INFRACOST_VERSION=${params.infracost_version} --build-arg ${params.cloud_nuke_version}"
                    reuseNode true
                }
            }
            environment {
                INFRACOST_API_KEY = credentials('jenkins-infracost-api-key')
            }
            steps {
                sh """infracost breakdown \\
                                --path ${PLAN_JSON} \\
                                --format json \\
                                --out-file ${INFRACOST_JSON}"""
            }
        }
        stage("Policy-Driven") {
            agent{
                docker{
                    image "aquasec/tfsec-ci:v${params.tfsec_version}"
                    reuseNode true
                }
            }
            environment {
                DEFECT_CATEGORY = '6'
                TEST_APPROACH = '3'
                TEST_FOLDER = 'tfsec'
                TEST_COMMAND = "tfsec . --no-color --custom-check-dir ${TEST_FOLDER}"
                TEST_TOOL = 'tfsec'
            }
            steps {
                sh """scripts/run_test.sh \\
                    --build-number ${BUILD_NUMBER} \\
                    --defect-category '${DEFECT_CATEGORY}' \\
                    --test-approach ${TEST_APPROACH} \\
                    --test-tool '${TEST_TOOL}' \\
                    --test-command '${TEST_COMMAND}' \\
                    --csv-file ${CSV_FILE}"""
            }
        }
        stage("Code-Driven 1: pytest") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image "databricksdocs/pytest:${params.pytest_version}"
                    reuseNode true
                }
            }
            environment {
                TEST_FOLDER = 'pytest'
                TEST_COMMAND = "pytest "
                TEST_TOOL = 'pytest'
            }
            steps {
                sh """scripts/run_grouped_tests.sh \\
                    --build-number ${BUILD_NUMBER} \\
                    --test-folder ${TEST_FOLDER} \\
                    --test-tool '${TEST_TOOL}' \\
                    --test-command '${TEST_COMMAND}' \\
                    --csv-file ${CSV_FILE}"""
            }
        }
        stage("Code-Driven 2: terraform test") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image "hashicorp/terraform:${params.terraform_version}"
                    reuseNode true
                }
            }
            environment {
                TEST_FOLDER = 'tests'
                TEST_APPROACH = '4'
                TEST_COMMAND = "terraform test -no-color -filter="
            }
            steps {
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY")]) {
                    sh """scripts/run_grouped_tests.sh \\
                        --build-number ${BUILD_NUMBER} \\
                        --test-folder ${TEST_FOLDER} \\
                        --test-approach ${TEST_APPROACH} \\
                        --test-command '${TEST_COMMAND}' \\
                        --csv-file ${CSV_FILE}"""
                }
            }
        }
        stage("Architecture-Driven 1: terraform test") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image "hashicorp/terraform:${params.terraform_version}"
                    reuseNode true
                }
            }
            when {
                expression { params.dynamic_testing == true }
            }
            environment {
                TEST_FOLDER = 'tests'
                TEST_APPROACH = '5'
                TEST_COMMAND = "terraform test -no-color -filter="
            }
            steps {
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY"),
                     usernamePassword(credentialsId: "terraform-db-credentials", usernameVariable: "DB_USR", passwordVariable: "DB_PWD") ]) {
                    script {
                        def success = true
                        try {
                            sh "echo 'Optimize runtime by deploying once instead of multiple times for compatible test cases'"
                            sh """scripts/run_test.sh \\
                                --build-number ${BUILD_NUMBER} \\
                                --defect-category NA \\
                                --test-approach ${TEST_APPROACH} \\
                                --test-tool 'terraform apply' \\
                                --test-command 'terraform apply plan.tfplan -no-color' \\
                                --csv-file ${CSV_FILE}"""
                            sh "echo 'Run tests'"
                            sh """scripts/run_grouped_tests.sh \\
                                --build-number ${BUILD_NUMBER} \\
                                --test-folder ${TEST_FOLDER} \\
                                --test-approach ${TEST_APPROACH} \\
                                --test-command '${TEST_COMMAND}' \\
                                --csv-file ${CSV_FILE}"""
                        } catch (Exception e) {
                            success = false
                        } finally {
                            sh """scripts/run_test.sh \\
                                --build-number ${BUILD_NUMBER} \\
                                --defect-category NA \\
                                --test-approach ${TEST_APPROACH} \\
                                --test-command 'terraform destroy -no-color -auto-approve -var=db_pwd=\$DB_PWD' \\
                                --csv-file ${CSV_FILE}"""
                            if (!success) {
                                error "One or more steps failed in the try block."
                            }
                        }
                        sh "echo 'Run test incompatible with pre-deployment'"
                        sh """scripts/run_test.sh \\
                            --build-number ${BUILD_NUMBER} \\
                            --defect-category 1 \\
                            --test-case 3 \\
                            --test-approach ${TEST_APPROACH} \\
                            --test-command 'terraform test -no-color -filter=tests/tc3_dc1_ta_5_no-predeployment.tftest.hcl' \\
                            --csv-file ${CSV_FILE}"""
                    }
                }
            }
        }
        stage("Architecture-Driven 2: Terratest") {
            agent{
                dockerfile{
                    dir 'terratest'
                    filename 'DOCKERFILE'
                    additionalBuildArgs "--build-arg TERRAFORM_VERSION=${params.terraform_version}"
                    reuseNode true
                }
            }
            when {
                expression { params.dynamic_testing == true }
            }
            environment {
                TEST_TOOL = 'terratest'
                // terratest test cases can run significantly longer than average go tests, so
                // we have to set a generous timeout here:
                TIMEOUT = '90m'
                // Executing individial test cases based on file names is faulty for terratest,
                // so we do not use the script 'run_grouped_tests.sh' here. Instead, we execute
                // the test cases individually by addressing the test function names:
                TC11 = "Test_tc11_dc5_ta5"
                TC14 = "Test_tc14_dc6_ta5"
                TEST_COMMAND = "go test -timeout ${TIMEOUT} -run "
                TEST_CONTEXT = "./terratest"
            }
            steps {
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY"),
                     usernamePassword(credentialsId: "terraform-db-credentials", usernameVariable: "DB_USR", passwordVariable: "DB_PWD") ]) {
                    sh """scripts/run_test.sh \\
                        --build-number ${BUILD_NUMBER} \\
                        --test-tool '${TEST_TOOL}' \\
                        --test-command "${TEST_COMMAND}${TC11}" \\
                        --change-directory ${TEST_CONTEXT} \\
                        --csv-file ${CSV_FILE}"""
                    sh """scripts/run_test.sh \\
                        --build-number ${BUILD_NUMBER} \\
                        --test-tool '${TEST_TOOL}' \\
                        --test-command "${TEST_COMMAND}${TC14}" \\
                        --change-directory ${TEST_CONTEXT} \\
                        --csv-file ${CSV_FILE}"""
                }
            }
        }       
        stage("Cost Calculation") {
            agent{
                dockerfile{
                    dir 'tools'
                    filename 'DOCKERFILE'
                    additionalBuildArgs "--build-arg INFRACOST_VERSION=${params.infracost_version} --build-arg ${params.cloud_nuke_version}"
                    reuseNode true
                }
            }
            when {
                expression { params.dynamic_testing == true }
            }
            steps {
                sh """scripts/extend_measurements_with_costs.py \\
                        --infracost-json ${INFRACOST_JSON} \\
                        --measurements-csv ${CSV_FILE}"""
            }
        }
    }
    post { 
        always { 
            archiveArtifacts artifacts: "*.csv, *.json",
                allowEmptyArchive: true

            script {
                if (params.nuke && params.dynamic_testing) {
                    // cloud-nuke
                    sh "docker build -t tools --build-arg INFRACOST_VERSION=${params.infracost_version} --build-arg CLOUD_NUKE_VERSION=${params.cloud_nuke_version} -f tools/DOCKERFILE ."
                    docker.image('tools').inside("--entrypoint=''") {
                        withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY")]) {
                            sh "cloud-nuke aws --config ./cloud-nuke.yaml --region ${REGION} --force"
                            // second run as especially VPCs are not always deleted in the first run
                            sh "cloud-nuke aws --config ./cloud-nuke.yaml --region ${REGION} --force"
                        }
                    }
                    
                    // cloud-nuke does not touch db subnet groups, so they might remain after 
                    // a crashed dynamic test. We delete them here to avoid errors in the next test run:
                    // cloud-nuke issue #623: https://github.com/gruntwork-io/cloud-nuke/issues/623
                    docker.image("amazon/aws-cli:${params.aws_cli_version}").inside("--entrypoint=''") {
                        withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY")]) {
                            // Define a variable to hold the output of the subnet groups query
                            def dbSubnetGroups = sh(script: """aws rds describe-db-subnet-groups \\
                                                                --region ${REGION} \\
                                                                --query 'DBSubnetGroups[*].DBSubnetGroupName' \\
                                                                --output text""", returnStdout: true).trim()

                            // Check if the output is not empty, indicating that there are subnet groups
                            if (dbSubnetGroups) {
                                // Split the output into an array, one element per line/subnet group
                                def groupsList = dbSubnetGroups.split("\\n")
                                // Iterate over the array and delete each subnet group
                                groupsList.each {
                                    sh """aws rds delete-db-subnet-group \\
                                        --db-subnet-group-name ${it} \\
                                        --region ${REGION} \\"""
                                }
                            } else {
                                echo "No DB Subnet Groups found to delete."
                            }
                        }
                    }
                }
            }

            cleanWs()
        }
    }
}
