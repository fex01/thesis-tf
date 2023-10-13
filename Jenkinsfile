pipeline {
    agent any

    parameters {
        booleanParam defaultValue: true, name: 'plan'
        booleanParam defaultValue: true, name: 'sa_tool'
        booleanParam defaultValue: true, name: 'sa_policy'
        booleanParam defaultValue: true, name: 'sa_unit'
        booleanParam defaultValue: false, name: 'deploy'
        booleanParam defaultValue: false, name: 'da_integration'
        booleanParam defaultValue: false, name: 'da_e2e'
        booleanParam defaultValue: true, name: 'destroy'
    }

    stages {
        stage("Build") {
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
                echo "Building"
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY"),
                     usernamePassword(credentialsId: "terraform-db-credentials", usernameVariable: "DB_USR", passwordVariable: "DB_PWD") ]) {
                    sh "terraform init -no-color"
                    sh "terraform plan -out plan.tfplan -refresh=false -no-color -var=db_pwd=\$DB_PWD"
                }
                    sh "terraform show -json plan.tfplan > plan.json"
            }
        }
        stage("SA: Policy Driven") {
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
                        sh "tfsec . --no-colour --no-code --include-passed --format json > tfsec_audit.json"
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
                        sh "regula run plan.json --input-type tf-plan --format json > regula_audit.json"
                    }
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
            }
            steps {
                echo "Deploying"
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY")]) {
                    sh "terraform apply plan.tfplan -no-color"
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
                withCredentials([usernamePassword(credentialsId: "aws-terraform-credentials", usernameVariable: "AWS_ACCESS_KEY_ID", passwordVariable: "AWS_SECRET_ACCESS_KEY"),
                     usernamePassword(credentialsId: "terraform-db-credentials", usernameVariable: "DB_USR", passwordVariable: "DB_PWD") ]) {
                    sh "terraform destroy -no-color -auto-approve -var=db_pwd=\$DB_PWD"
                }
            }
        }
    }
    post { 
        always { 
                //sh "tr -cd '[:print:]\n' < tfsec_report.txt > tmp.txt && mv tmp.txt tfsec_report.txt"
                // archiveArtifacts "*_audit.json"
                archiveArtifacts "plan.tfplan"
        }
    }
}
