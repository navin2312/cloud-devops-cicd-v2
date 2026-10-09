
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ghcr.io/navin2312/cloud-devops-app'
        IMAGE_TAG = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                bat 'docker build -t %IMAGE_NAME%:%IMAGE_TAG% .\\app'
            }
        }

        stage('Test Docker Image') {
            steps {
                bat 'docker image inspect %IMAGE_NAME%:%IMAGE_TAG%'
            }
        }

        stage('Diagnose GHCR Credentials') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    powershell '''
                        if ([string]::IsNullOrWhiteSpace($env:GHCR_USER)) {
                            throw "GHCR username is empty"
                        }

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_TOKEN)) {
                            throw "GHCR token is empty"
                        }

                        Write-Output "GHCR username is present."
                        Write-Output "GHCR token is present."
                        Write-Output "Token length: $($env:GHCR_TOKEN.Length)"
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'CI/CD pipeline diagnostic finished.'
        }
    }
}
