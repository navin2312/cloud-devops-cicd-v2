```groovy
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
                        $ErrorActionPreference = "Continue"

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_USER)) {
                            throw "GHCR username is empty"
                        }

                        if ([string]::IsNullOrWhiteSpace($env:GHCR_TOKEN)) {
                            throw "GHCR token is empty"
                        }

                        Write-Output "Username is present."
                        Write-Output "Token is present."

                        $env:GHCR_TOKEN |
                            docker login ghcr.io `
                                --username $env:GHCR_USER `
                                --password-stdin

                        $loginExitCode = $LASTEXITCODE

                        if ($loginExitCode -ne 0) {
                            throw "Docker login failed with exit code $loginExitCode"
                        }

                        Write-Output "GHCR login succeeded."
                    '''
                }
            }
        }
    }
}
```