pipeline {
    agent any

    parameters {
        booleanParam defaultValue: false, name: 'dynamic_testing', description: 'Run dynamic tests'
    }
    environment {
        CSV_FILE = 'timings.csv'
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
                sh "terraform show -json plan.tfplan > plan.json"
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
            }
            steps {
                sh """scripts/run_grouped_tests.sh \\
                    --build-number ${BUILD_NUMBER} \\
                    --test-folder ${TEST_FOLDER} \\
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
                TEST_COMMAND = "terraform test -filter="
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
            environment {
                TEST_FOLDER = 'tests'
                TEST_APPROACH = '5'
                TEST_COMMAND = "terraform test -filter="
            }
            when {
                expression { params.dynamic_testing == true }
            }
            steps {
                script {
                    def start_time = System.currentTimeMillis()
                    withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY")]) {
                        sh "terraform apply plan.tfplan -no-color"
                    }
                    def end_time = System.currentTimeMillis()
                    def runtime = end_time - start_time
                    def csv_entry = "${BUILD_NUMBER},deploy,NA,${runtime}"
                    sh "echo '${csv_entry}' >> timings.csv"
                }
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY")]) {
                    sh "echo 'Optimize runtime by deploying once instead of multiple times for compatible test cases'"
                    sh """scripts/run_grouped_tests.sh \\
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
                    sh "echo 'Destroy Test Deployment'"
                    sh """scripts/run_grouped_tests.sh \\
                        --build-number ${BUILD_NUMBER} \\
                        --defect-category NA \\
                        --test-approach ${TEST_APPROACH} \\
                        --test-tool 'terraform destroy' \\
                        --test-command 'terraform destroy -no-color -auto-approve -var=db_pwd=\$DB_PWD' \\
                        --csv-file ${CSV_FILE}"""
                }
            }
        }
        // stage("ta5: integration testing (terratest)") {
        //     agent{
        //         dockerfile{
        //             dir 'terratest'
        //             filename 'DOCKERFILE'
        //             reuseNode true
        //         }
        //     }
        //     when {
        //         expression { params.dynamic_testing == true }
        //     }
        //     environment {
        //         DEFECT_CATEGORY = 5
        //         TEST_CASE = 1
        //         TEST_APPROACH = 5

        //         TEST_COMMAND = "cd terratest && go test -timeout 30m && cd .."
        //     }
        //     steps {
        //         withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY")]) {
        //             sh """scripts/run_test.sh \\
        //                 --build-number ${BUILD_NUMBER} \\
        //                 --test-approach ${TEST_APPROACH} \\
        //                 --test-command '${TEST_COMMAND}' \\
        //                 --csv-file ${CSV_FILE}"""
        //         }
        //     }
        // }
    }
    post { 
        always { 
            archiveArtifacts artifacts: "*.csv",
                allowEmptyArchive: true
        }
    }
}
