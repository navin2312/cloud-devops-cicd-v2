pipeline {
    agent any

    stages {
        stage('Diagnose GitHub Token') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    powershell '''
                        $ErrorActionPreference = "Stop"

                        $headers = @{
                            Authorization = "Bearer $env:GHCR_TOKEN"
                            Accept = "application/vnd.github+json"
                            "User-Agent" = "Jenkins-GHCR-Diagnostic"
                        }

                        try {
                            $response = Invoke-WebRequest `
                                -Uri "https://api.github.com/user" `
                                -Headers $headers `
                                -UseBasicParsing

                            Write-Output "GitHub API status: $([int]$response.StatusCode)"
                            Write-Output "GitHub token is accepted by the API."
                        }
                        catch {
                            $status = 0
                            if ($_.Exception.Response) {
                                $status = [int]$_.Exception.Response.StatusCode
                            }

                            Write-Output "GitHub API status: $status"
                            throw "GitHub token validation failed."
                        }

                        $env:GHCR_TOKEN |
                            docker login ghcr.io `
                                --username $env:GHCR_USER `
                                --password-stdin

                        if ($LASTEXITCODE -ne 0) {
                            throw "GHCR login failed."
                        }

                        Write-Output "GHCR login succeeded."
                    '''
                }
            }
        }
    }
}
