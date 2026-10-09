
pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    environment {
        IMAGE_NAME = 'ghcr.io/navin2312/cloud-devops-app'
        DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = bat(
                        script: '@git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()
                }
                echo 'Source code checkout completed.'
            }
        }

        stage('Validate Environment') {
            steps {
                powershell '''
                    $ErrorActionPreference = "Stop"

                    Write-Output "Checking Docker..."

                    docker version
                    if ($LASTEXITCODE -ne 0) {
                        throw "Docker is unavailable."
                    }

                    $osType = docker info --format '{{.OSType}}'
                    if ($LASTEXITCODE -ne 0) {
                        throw "Unable to query Docker engine."
                    }

                    Write-Output "Docker OS: $osType"

                    if ($osType.Trim() -ne "linux") {
                        throw "Docker Desktop must use Linux containers."
                    }

                    Write-Output "Environment validation succeeded."
                '''
            }
        }

        stage('Authenticate to GHCR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    powershell '''
                        $ErrorActionPreference = "Stop"

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_USER)) {
                            throw "GitHub username is empty."
                        }

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_TOKEN)) {
                            throw "GitHub token is empty."
                        }

                        if ($env:GHCR_USER -ne "navin2312") {
                            throw "Unexpected GitHub username in Jenkins credentials."
                        }

                        # Verify the token's GitHub account.
                        $headers = @{
                            Authorization = "Bearer $env:GHCR_TOKEN"
                            Accept = "application/vnd.github+json"
                            "User-Agent" = "Jenkins-GHCR-Pipeline"
                        }

                        try {
                            $response = Invoke-WebRequest `
                                -Uri "https://api.github.com/user" `
                                -Headers $headers `
                                -UseBasicParsing

                            $account = $response.Content | ConvertFrom-Json
                        }
                        catch {
                            throw "GitHub API authentication failed or the API is unreachable."
                        }

                        if ($account.login -ne $env:GHCR_USER) {
                            throw "Token account does not match the configured GitHub username."
                        }

                        Write-Output "GitHub account verification succeeded."

                        # Use an isolated Docker credential configuration.
                        $dockerConfig = Join-Path $env:WORKSPACE ".docker-ci"

                        if (Test-Path $dockerConfig) {
                            Remove-Item -LiteralPath $dockerConfig `
                                -Recurse -Force
                        }

                        New-Item -ItemType Directory `
                            -Path $dockerConfig -Force | Out-Null

                        $env:DOCKER_CONFIG = $dockerConfig

                        Write-Output "Logging in to GHCR..."

                        $env:GHCR_TOKEN |
                            docker login ghcr.io `
                                --username $env:GHCR_USER `
                                --password-stdin

                        if ($LASTEXITCODE -ne 0) {
                            throw "GHCR login failed. Check the token and registry permissions."
                        }

                        Write-Output "GHCR login succeeded."
                    '''
                }
            }
        }

        stage('Build Image') {
            steps {
                powershell '''
                    $ErrorActionPreference = "Stop"

                    $image = "$env:IMAGE_NAME"

                    Write-Output "Building image tag: $env:IMAGE_TAG"

                    docker build `
                        -t "${image}:$env:IMAGE_TAG" `
                        -t "${image}:latest" `
                        -f app/Dockerfile app

                    if ($LASTEXITCODE -ne 0) {
                        throw "Docker image build failed."
                    }

                    Write-Output "Docker image build succeeded."
                '''
            }
        }

        stage('Push Image') {
            steps {
                powershell '''
                    $ErrorActionPreference = "Stop"

                    $image = "$env:IMAGE_NAME"

                    Write-Output "Pushing commit-tagged image..."

                    docker push "${image}:$env:IMAGE_TAG"

                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to push commit-tagged image."
                    }

                    Write-Output "Pushing latest image..."

                    docker push "${image}:latest"

                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to push latest image."
                    }

                    Write-Output "Both image tags were pushed successfully."
                '''
            }
        }
    }

    post {
        always {
            withCredentials([usernamePassword(
                credentialsId: 'ghcr-credentials',
                usernameVariable: 'GHCR_USER',
                passwordVariable: 'GHCR_TOKEN'
            )]) {
                powershell '''
                    $dockerConfig = Join-Path $env:WORKSPACE ".docker-ci"

                    if (Test-Path $dockerConfig) {
                        $env:DOCKER_CONFIG = $dockerConfig
                        docker logout ghcr.io 2>$null | Out-Null

                        Remove-Item -LiteralPath $dockerConfig `
                            -Recurse -Force -ErrorAction SilentlyContinue
                    }

                    Write-Output "Docker credential cleanup completed."
                '''
            }
        }

        success {
            echo 'CI/CD pipeline completed successfully.'
            echo 'The commit-tagged and latest images are available in GHCR.'
        }

        failure {
            echo 'CI/CD pipeline failed. Check the first failing stage in Console Output.'
        }
    }
}
