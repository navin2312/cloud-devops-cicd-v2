
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ghcr.io/navin2312/cloud-devops-app'
        IMAGE_TAG  = 'latest'
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
                    bat 'docker login ghcr.io -u %GHCR_USER% --password-stdin < NUL'
                    bat 'docker push %IMAGE_NAME%:%IMAGE_TAG%'
                }
            }
        }
    }
}
