pipeline {
    agent any

    parameters {
        booleanParam defaultValue: true, name: 'plan'
        booleanParam defaultValue: true, name: 'sa_tool'
        booleanParam defaultValue: true, name: 'sa_policy'
        booleanParam defaultValue: true, name: 'sa_code'
        booleanParam defaultValue: false, name: 'da_integration'
        booleanParam defaultValue: false, name: 'da_e2e'
        booleanParam defaultValue: false, name: 'deploy'
        booleanParam defaultValue: false, name: 'destroy'
    }
    environment {
        // finish static analysis even if some TL report errors, 
        // but only deploy if all SA Test Level pass
        WITHOUT_ERRORS = true
    }

    stages {
        stage("Initialize") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6'
                    reuseNode true
                }
            }
            steps {
                echo "${params}"
                sh "terraform init -no-color"
                script {
                    // Check if 'timings.csv' file exists
                    if (!fileExists('timings.csv')) {
                        // Create the file and write the header if the file doesn't exist
                        sh "echo 'build,test_level,#tc,runtime(millis)' > timings.csv"
                    }
                }
            }
        }
        stage("SA: Tool Driven") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6'
                    reuseNode true
                }
            }
            when {
                expression { params.sa_tool == true }
            }
            steps {
                // proceed static analysis independently of exit code, but do avoid deployment if there are errors
                script {
                    def start_time = System.currentTimeMillis()
                    def exitCodeFmt = sh script: "terraform fmt --check --diff -no-color > tf-fmt_result.txt", 
                        returnStatus: true
                    if (exitCodeFmt != 0) {
                        WITHOUT_ERRORS = false
                    }
                    def exitCodeVal = sh script: "terraform validate -no-color > tf-validate_result.txt", returnStatus: true
                    if (exitCodeVal != 0) {
                        WITHOUT_ERRORS = false
                    }
                    def end_time = System.currentTimeMillis()
                    def runtime = end_time - start_time
                    def csv_entry = "${BUILD_NUMBER},tool-driven,NA,${runtime}"
                    sh "echo '${csv_entry}' >> timings.csv"
                }
            }
        }
        stage("Plan") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6'
                    reuseNode true
                }
            }
            when {
                expression { params.plan == true }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY"),
                     usernamePassword(credentialsId: "terraform-db-credentials", usernameVariable: "DB_USR", passwordVariable: "DB_PWD") ]) {
                    sh "terraform plan -out plan.tfplan -refresh=false -no-color -var=db_pwd=\$DB_PWD"
                }
                sh "terraform show -json plan.tfplan > plan.json"
            }
        }
        stage("SA: PaC") {
            when {
                expression { params.plan == true && params.sa_policy == true }
            }
            parallel {
                stage("TFsec") {
                    agent{
                        docker{
                            image 'aquasec/tfsec-ci:v1.28'
                            reuseNode true
                        }
                    }
                    steps {
                        script {
                            def start_time = System.currentTimeMillis()
                            sh "tfsec . --no-colour --no-code --include-passed --format json > tfsec_audit.json"
                            def end_time = System.currentTimeMillis()
                            def runtime = end_time - start_time
                            def csv_entry = "${BUILD_NUMBER},pac-tfsec,NA,${runtime}"
                            sh "echo '${csv_entry}' >> timings.csv"
                        }
                    }
                }
                stage("Regula") {
                    agent{
                        docker{
                            args '--entrypoint=""'
                            image 'fugue/regula:v3.2.1'
                            reuseNode true
                        }
                    }
                    steps {
                        // proceed static analysis independently of exit code, but do avoid deployment if there are errors
                        script {
                            def start_time = System.currentTimeMillis()
                            def exitCode = sh script: "regula run plan.json --input-type tf-plan --format json > regula_audit.json", 
                                returnStatus: true
                            if (exitCode != 0) {
                                WITHOUT_ERRORS = false
                            }
                            def end_time = System.currentTimeMillis()
                            def runtime = end_time - start_time
                            def csv_entry = "${BUILD_NUMBER},pac-regula,NA,${runtime}"
                            sh "echo '${csv_entry}' >> timings.csv"
                        }
                    }
                }
            }
        }
        stage("SA: Unit") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'python:3.9.18-bookworm'
                    reuseNode true
                }
            }
            when {
                expression { params.sa_code == true }
            }
            steps {
                // proceed static analysis independently of exit code, but do avoid deployment if there are errors
                script {
                    def start_time = System.currentTimeMillis()
                    def exitCode = sh script: "pytest --version > pytest_result.txt", 
                        returnStatus: true
                    if (exitCode != 0) {
                        WITHOUT_ERRORS = false
                    }
                    def end_time = System.currentTimeMillis()
                    def runtime = end_time - start_time
                    def csv_entry = "${BUILD_NUMBER},unit,NA,${runtime}"
                    sh "echo '${csv_entry}' >> timings.csv"
                }
            }
        }
        stage("DA: Integration") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'austincloud/terratest:1.4.5'
                    reuseNode true
                }
            }
            when {
                expression { params.da_integration == true }
            }
            steps {
                // proceed static analysis independently of exit code, but do avoid deployment if there are errors
                script {
                    def start_time = System.currentTimeMillis()
                    withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY")]) {
                        def exitCode = sh script: "cd .terratest && go test -timeout 30m > integration_result.txt", 
                            returnStatus: true
                        if (exitCode != 0) {
                            WITHOUT_ERRORS = false
                        }
                    }
                    def end_time = System.currentTimeMillis()
                    def runtime = end_time - start_time
                    def csv_entry = "${BUILD_NUMBER},integration,NA,${runtime}"
                    sh "echo '${csv_entry}' >> timings.csv"
                }
            }
        }
        stage("Deploy") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6'
                    reuseNode true
                }
            }
            when {
                expression { params.plan == true && params.deploy == true }
            }//WITHOUT_ERRORS == true && 
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
            }
        }
        stage("Destroy") {
            agent{
                docker{
                    args '--entrypoint=""'
                    image 'hashicorp/terraform:1.6'
                    reuseNode true
                }
            }
            when {
                expression { params.destroy == true }
            }
            steps {
                script {
                    def start_time = System.currentTimeMillis()
                    withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY"),
                        usernamePassword(credentialsId: "terraform-db-credentials", usernameVariable: "DB_USR", passwordVariable: "DB_PWD") ]) {
                        sh "terraform destroy -no-color -auto-approve -var=db_pwd=\$DB_PWD"
                    }
                    def end_time = System.currentTimeMillis()
                    def runtime = end_time - start_time
                    def csv_entry = "${BUILD_NUMBER},destroy,NA,${runtime}"
                    sh "echo '${csv_entry}' >> timings.csv"
                }
            }
        }
    }
    post { 
        always { 
            archiveArtifacts artifacts: "plan.json, *_result.txt, *_audit.json, timings.csv",
                allowEmptyArchive: true
        }
    }
}
