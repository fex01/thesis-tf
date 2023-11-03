pipeline {
    agent any

    parameters {
        booleanParam defaultValue: false, name: 'dynamic_testing', description: 'Run dynamic tests'
        booleanParam defaultValue: true, name: 'use_cloud_nuke', description: 'Use only in test env - highly destructive!'
    }
    environment {
        CSV_FILE = 'timings.csv'
        REGION = 'eu-west-3'
        PLAN_JSON = 'plan.json'
        PLAN_TXT = 'plan.txt'
        INFRACOST_JSON = 'infracost.json'
    }

    stages {
        stage("initialize") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6.2'
                    reuseNode true
                }
            }
            steps {
                echo "${params}"
                sh "terraform init -no-color"
            }
        }
        stage("ta1: format") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6.2'
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
                    --defect-category '${DEFECT_CATEGORY}' \\
                    --test-approach ${TEST_APPROACH} \\
                    --test-command '${TEST_COMMAND}' \\
                    --csv-file ${CSV_FILE}"""
            }
        }
        stage("ta2: validate") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6.2'
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
        stage("plan") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6.2'
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
        stage('cost estimation') {
            agent{
                dockerfile{
                    dir 'tools'
                    filename 'DOCKERFILE'
                    additionalBuildArgs '--build-arg INFRACOST_VERSION=0.10.29'
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
        stage("ta3: PaC (tfsec)") {
            agent{
                docker{
                    image 'aquasec/tfsec-ci:v1.28'
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
        stage("ta4: unit testing (pytest)") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'databricksdocs/pytest:0.3.4-rc.2'
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
        stage("ta4: unit testing (terraform test)") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6.2'
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
        stage("ta5: integration testing (terraform test)") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6.2'
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
                            --test-case 1 \\
                            --test-approach ${TEST_APPROACH} \\
                            --test-command 'terraform test -no-color -filter=tests/dc1_tc1_ta_5_no-predeployment.tftest.hcl' \\
                            --csv-file ${CSV_FILE}"""
                    }
                }
            }
        }
        stage("ta5: integration testing (terratest)") {
            agent{
                dockerfile{
                    dir 'terratest'
                    filename 'DOCKERFILE'
                    reuseNode true
                }
            }
            when {
                expression { params.dynamic_testing == true }
            }
            environment {
                DEFECT_CATEGORY = 5
                TEST_CASE = 1
                TEST_APPROACH = 5
                TEST_TOOL = 'terratest'
                TEST_COMMAND = "go test -timeout 45m"
                TEST_CONTEXT = "./terratest"
            }
            steps {
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY"),
                     usernamePassword(credentialsId: "terraform-db-credentials", usernameVariable: "DB_USR", passwordVariable: "DB_PWD") ]) {
                    sh """scripts/run_test.sh \\
                        --build-number ${BUILD_NUMBER} \\
                        --defect-category ${DEFECT_CATEGORY} \\
                        --test-case ${TEST_CASE} \\
                        --test-approach ${TEST_APPROACH} \\
                        --test-tool '${TEST_TOOL}' \\
                        --test-command '${TEST_COMMAND}' \\
                        --change-directory ${TEST_CONTEXT} \\
                        --csv-file ${CSV_FILE}"""
                }
            }
        }
        stage("nuke") {
            agent{
                dockerfile{
                    dir 'tools'
                    filename 'DOCKERFILE'
                    reuseNode true
                }
            }
            when {
                expression { params.use_cloud_nuke == true } //&& params.dynamic_testing == true }
            }
            steps {
                script {
                    def toolAvailable = sh(script: "which cloud-nuke", returnStatus: true)
                    if (toolAvailable == 0) {
                        sh "echo 'cloud-nuke tool is available, proceeding to nuke...'"
                        withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY")]) {
                            sh "cloud-nuke aws --config ./cloud-nuke.yaml --region ${REGION} --force"
                            // second run as especially VPCs are not always deleted in the first run
                            sh "cloud-nuke aws --config ./cloud-nuke.yaml --region ${REGION} --force"
                        }
                    } else {
                        sh "echo 'Cloud-nuke tool is not available, skipping this stage.'"
                    }
                }
            }
        }

    }
    post { 
        always { 
            archiveArtifacts artifacts: "*.csv, *.json",
                allowEmptyArchive: true
            cleanWs()
        }
    }
}
