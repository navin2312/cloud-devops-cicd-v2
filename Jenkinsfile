
pipeline {
    agent any

    stages {
        stage('Test GHCR Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    powershell '''
                        $ErrorActionPreference = "Stop"

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_TOKEN)) {
                            throw "GHCR token is empty"
                        }

                        $env:GHCR_TOKEN |
                            docker login ghcr.io -u $env:GHCR_USER --password-stdin

                        if ($LASTEXITCODE -ne 0) {
                            throw "GHCR login failed"
                        }

                        Write-Output "GHCR login succeeded."
                    '''
                }
            }
        }
    }
}
