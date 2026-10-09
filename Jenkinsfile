
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

        stage('Push to GHCR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    powershell '''
                        $ErrorActionPreference = "Stop"
                        $env:GHCR_TOKEN | docker login ghcr.io -u $env:GHCR_USER --password-stdin
                        if ($LASTEXITCODE -ne 0) {
                            throw "GHCR login failed"
                        }

                        docker push "$env:IMAGE_NAME`:$env:IMAGE_TAG"
                        if ($LASTEXITCODE -ne 0) {
                            throw "GHCR push failed"
                        }
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'CI/CD pipeline execution finished.'
        }
    }
}

