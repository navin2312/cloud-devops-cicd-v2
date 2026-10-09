
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        IMAGE_NAME = 'ghcr.io/navin2312/cloud-devops-app'
        DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'
    }

    stages {
        stage('Validate Environment') {
            steps {
                powershell '''
                    $ErrorActionPreference = "Continue"

                    if (!(Test-Path "app/Dockerfile")) {
                        throw "Missing app/Dockerfile"
                    }

                    if (!(Test-Path "app/index.html")) {
                        throw "Missing app/index.html"
                    }

                    $env:DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'

                    Write-Output "Checking Docker engine..."

                    $info = docker info --format '{{.OSType}}' 2>&1
                    $dockerExitCode = $LASTEXITCODE

                    $info | ForEach-Object { Write-Output "$_" }

                    if ($dockerExitCode -ne 0) {
                        throw "Cannot connect to Docker Desktop. Check that Docker Desktop is running and Jenkins can access its named pipe."
                    }

                    if (($info -join "").Trim() -ne "linux") {
                        throw "Docker is not using Linux containers."
                    }

                    Write-Output "Docker engine is ready."
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
                        $ErrorActionPreference = "Continue"

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_USER)) {
                            throw "Jenkins GitHub username is empty."
                        }

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_TOKEN)) {
                            throw "Jenkins GitHub token is empty."
                        }

                        if ($env:GHCR_USER -ne "navin2312") {
                            throw "Unexpected GitHub username in Jenkins credentials."
                        }

                        # Verify the PAT and the account it authenticates.
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
                            throw "GitHub API rejected the Jenkins token or could not be reached."
                        }

                        Write-Output "Authenticated GitHub account: $($account.login)"

                        if ($account.login -ne $env:GHCR_USER) {
                            throw "GitHub account does not match the Jenkins username."
                        }

                        # Confirm required scopes when GitHub reports them.
                        $scopeHeader = [string]$response.Headers["X-OAuth-Scopes"]

                        if (-not [string]::IsNullOrWhiteSpace($scopeHeader)) {
                            $scopes = @($scopeHeader -split ',\\s*')

                            if (($scopes -notcontains "read:packages") -or
                                ($scopes -notcontains "write:packages")) {
                                throw "PAT needs both read:packages and write:packages scopes."
                            }

                            Write-Output "Required package scopes are present."
                        }
                        else {
                            Write-Output "GitHub did not report OAuth scopes; testing registry login directly."
                        }

                        # Use an isolated Docker config to avoid stale credentials
                        # or a per-user credential-store configuration.
                        $env:DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'
                        $dockerConfig = Join-Path $env:WORKSPACE ".docker-ci"

                        if (Test-Path $dockerConfig) {
                            Remove-Item -LiteralPath $dockerConfig -Recurse -Force
                        }

                        New-Item -ItemType Directory -Path $dockerConfig -Force | Out-Null
                        $env:DOCKER_CONFIG = $dockerConfig

                        Write-Output "Authenticating to GitHub Container Registry..."

                        $loginOutput = $env:GHCR_TOKEN |
                            docker login ghcr.io `
                                --username $env:GHCR_USER `
                                --password-stdin 2>&1

                        $loginExitCode = $LASTEXITCODE

                        $loginOutput | ForEach-Object { Write-Output "$_" }

                        if ($loginExitCode -ne 0) {
                            throw "GHCR authentication failed. Check the PAT permissions and registry access."
                        }

                        Write-Output "GHCR authentication succeeded."
                    '''
                }
            }
        }

        stage('Build Image') {
            steps {
                powershell '''
                    $ErrorActionPreference = "Continue"
                    $env:DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'
                    $env:DOCKER_CONFIG = Join-Path $env:WORKSPACE ".docker-ci"

                    $commitOutput = git rev-parse --short=12 HEAD
                    $gitExitCode = $LASTEXITCODE

                    if ($gitExitCode -ne 0) {
                        throw "Could not determine the Git commit."
                    }

                    $commit = ($commitOutput | Out-String).Trim()
                    $image = $env:IMAGE_NAME
                    $commitTag = "${image}:${commit}"
                    $latestTag = "${image}:latest"

                    Write-Output "Building $commitTag"

                    $buildOutput = docker build --pull `
                        --file app/Dockerfile `
                        --tag $commitTag `
                        --tag $latestTag `
                        app 2>&1

                    $buildExitCode = $LASTEXITCODE
                    $buildOutput | ForEach-Object { Write-Output "$_" }

                    if ($buildExitCode -ne 0) {
                        throw "Docker image build failed."
                    }

                    Write-Output "Image build succeeded."
                '''
            }
        }

        stage('Push Image') {
            steps {
                powershell '''
                    $ErrorActionPreference = "Continue"
                    $env:DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'
                    $env:DOCKER_CONFIG = Join-Path $env:WORKSPACE ".docker-ci"

                    $commitOutput = git rev-parse --short=12 HEAD
                    $gitExitCode = $LASTEXITCODE

                    if ($gitExitCode -ne 0) {
                        throw "Could not determine the Git commit."
                    }

                    $commit = ($commitOutput | Out-String).Trim()
                    $image = $env:IMAGE_NAME
                    $tags = @(
                        "${image}:${commit}",
                        "${image}:latest"
                    )

                    foreach ($imageTag in $tags) {
                        Write-Output "Pushing $imageTag"

                        $pushOutput = docker push $imageTag 2>&1
                        $pushExitCode = $LASTEXITCODE

                        $pushOutput | ForEach-Object { Write-Output "$_" }

                        if ($pushExitCode -ne 0) {
                            throw "Failed to push $imageTag. Check GHCR package permissions."
                        }
                    }

                    Write-Output "Both image tags were pushed successfully."
                '''
            }
        }
    }

    post {
        always {
            powershell '''
                $ErrorActionPreference = "Continue"

                $env:DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'
                $dockerConfig = Join-Path $env:WORKSPACE ".docker-ci"
                $env:DOCKER_CONFIG = $dockerConfig

                if (Test-Path $dockerConfig) {
                    # Remove the temporary registry login and its local config.
                    $null = docker logout ghcr.io 2>&1

                    Remove-Item -LiteralPath $dockerConfig `
                        -Recurse -Force -ErrorAction SilentlyContinue
                }

                Write-Output "Temporary Docker credentials cleaned up."
            '''
        }
    }
}
