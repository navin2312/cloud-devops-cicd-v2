

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        EC2_HOST = '13.204.79.39'
        EC2_USER = 'ec2-user'
        SSH_CREDENTIALS = 'ec2-deploy-key'
        APP_NAME = 'cloud-devops-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate Application') {
            steps {
                powershell '''
                    $ErrorActionPreference = "Stop"

                    if (!(Test-Path "app/index.html")) {
                        throw "Missing app/index.html"
                    }

                    if (!(Test-Path "app/Dockerfile")) {
                        throw "Missing app/Dockerfile"
                    }

                    Write-Output "Application files validated."
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-deploy-key',
                        usernameVariable: 'SSH_USER',
                        keyFileVariable: 'SSH_KEY'
                    )
                ]) {
                    powershell '''
                        $ErrorActionPreference = "Stop"

                        $hostName = $env:EC2_HOST
                        $user = $env:SSH_USER
                        $key = $env:SSH_KEY

                        $sshOptions = @(
                            "-i", $key,
                            "-o", "BatchMode=yes",
                            "-o", "ConnectTimeout=15",
                            "-o", "StrictHostKeyChecking=accept-new"
                        )

                        Write-Output "Checking SSH connection to EC2..."

                        ssh @sshOptions "$user@$hostName" "echo SSH connection successful"

                        if ($LASTEXITCODE -ne 0) {
                            throw "SSH connection to EC2 failed."
                        }

                        Write-Output "Transferring website files..."

                        scp -i $key `
                            -o BatchMode=yes `
                            -o StrictHostKeyChecking=accept-new `
                            app/index.html `
                            "${user}@${hostName}:/tmp/index.html"

                        if ($LASTEXITCODE -ne 0) {
                            throw "Website file transfer failed."
                        }

                        Write-Output "Deploying Apache container..."

                        $remoteCommand = 'sudo docker pull httpd:2.4 && sudo docker rm -f cloud-devops-app >/dev/null 2>&1 || true; sudo docker run -d --name cloud-devops-app --restart unless-stopped -p 80:80 -v /tmp/index.html:/usr/local/apache2/htdocs/index.html:ro httpd:2.4'

                        ssh @sshOptions "$user@$hostName" $remoteCommand

                        if ($LASTEXITCODE -ne 0) {
                            throw "Deployment on EC2 failed."
                        }

                        Write-Output "Deployment command completed."
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                powershell '''
                    $ErrorActionPreference = "Stop"

                    Start-Sleep -Seconds 5

                    $url = "http://$env:EC2_HOST"
                    $response = Invoke-WebRequest -Uri $url -TimeoutSec 30

                    if ($response.StatusCode -ne 200) {
                        throw "Website verification failed."
                    }

                    Write-Output "Deployment successful!"
                    Write-Output "Website: $url"
                    Write-Output "HTTP status: $($response.StatusCode)"
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check Console Output for the failing stage.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
