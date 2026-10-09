
pipeline {
    agent any

    stages {
        stage('Diagnose GHCR Authentication') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    powershell '''
                        $ErrorActionPreference = "Stop"

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_USER)) {
                            throw "Jenkins username is missing."
                        }

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_TOKEN)) {
                            throw "Jenkins token is missing."
                        }

                        $sha = [Security.Cryptography.SHA256]::Create()

                        try {
                            $bytes = [Text.Encoding]::UTF8.GetBytes($env:GHCR_TOKEN)
                            $fingerprint = [BitConverter]::ToString(
                                $sha.ComputeHash($bytes)
                            ).Replace("-", "").Substring(0, 12)

                            Write-Output "Jenkins PAT fingerprint: $fingerprint"
                        }
                        finally {
                            $sha.Dispose()
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
                            throw "The Jenkins username does not match the GitHub account."
                        }

                        $ErrorActionPreference = "Continue"

                        $env:GHCR_TOKEN |
                            docker login ghcr.io `
                                --username $env:GHCR_USER `
                                --password-stdin

                        $loginExitCode = $LASTEXITCODE

                        if ($loginExitCode -ne 0) {
                            throw "GHCR login failed with exit code $loginExitCode."
                        }

                        Write-Output "GHCR login succeeded."
                    '''
                }
            }
        }
    }
}
