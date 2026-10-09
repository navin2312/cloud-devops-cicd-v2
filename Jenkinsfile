
pipeline {
    agent any

    stages {
        stage('Diagnose GitHub and GHCR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    powershell '''
                        $ErrorActionPreference = "Stop"

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_USER)) {
                            throw "GitHub username is missing from Jenkins credentials."
                        }

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_TOKEN)) {
                            throw "GitHub token is missing from Jenkins credentials."
                        }

                        $headers = @{
                            Authorization = "Bearer $env:GHCR_TOKEN"
                            Accept = "application/vnd.github+json"
                            "User-Agent" = "Jenkins-GHCR-Diagnostic"
                        }

                        $response = Invoke-WebRequest `
                            -Uri "https://api.github.com/user" `
                            -Headers $headers `
                            -UseBasicParsing

                        $user = $response.Content | ConvertFrom-Json

                        Write-Output "Authenticated GitHub account: $($user.login)"

                        if ($user.login -ne $env:GHCR_USER) {
                            throw "Jenkins credential username does not match the authenticated GitHub account."
                        }

                        if ($response.Headers["X-OAuth-Scopes"]) {
                            Write-Output "Token scopes: $($response.Headers['X-OAuth-Scopes'])"
                        } else {
                            Write-Output "Token scopes are not reported by this API response."
                        }

                        $env:GHCR_TOKEN |
                            docker login ghcr.io `
                                --username $env:GHCR_USER `
                                --password-stdin

                        $loginExitCode = $LASTEXITCODE

                        if ($loginExitCode -ne 0) {
                            throw "GHCR login failed with exit code $loginExitCode."
                        }

                        Write-Output "GHCR authentication succeeded."
                    '''
                }
            }
        }
    }
}
