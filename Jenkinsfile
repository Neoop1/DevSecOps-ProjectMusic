pipeline{
    agent any
    tools{
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/Neoop1/DevSecOps-ProjectMusic.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Spotify \
                    -Dsonar.projectKey=Spotify '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token' 
                }
            } 
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('OWASP FS-SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build"){
            steps{
                script{
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                       sh "/var/jenkins_home/tools/org.jenkinsci.plugins.docker.commons.tools.DockerTool/docker/bin/docker build  -t spotify ."
                       sh "/var/jenkins_home/tools/org.jenkinsci.plugins.docker.commons.tools.DockerTool/docker/bin/docker tag spotify neoop1/spotify:latest"
                    }
                }
            }
        }
        
        stage("Docker Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker'){   
                       sh "/var/jenkins_home/tools/org.jenkinsci.plugins.docker.commons.tools.DockerTool/docker/bin/docker push neoop1/spotify:latest"
                    }
                }
            }
        }
        stage("TRIVY"){
            steps{
                sh "trivy image neoop1/spotify:latest > trivyimage.txt" 
            }
        }
        stage('Deploy to container'){
            steps{
                sh '/var/jenkins_home/tools/org.jenkinsci.plugins.docker.commons.tools.DockerTool/docker/bin/docker run -d -p 8081:80 neoop1/spotify:latest'
            }
        }
        stage('Deploy to kubernets'){
            steps{
                script{
                    dir('Kubernetes') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                                sh 'kubectl apply -f deployment.yml'
                                sh 'kubectl apply -f service.yml'
                        }   
                    }
                }
            }
        }

    }
    post {
     always {
        emailext attachLog: true,
            subject: "'${currentBuild.result}'",
            body: "Project: ${env.JOB_NAME}<br/>" +
                "Build Number: ${env.BUILD_NUMBER}<br/>" +
                "URL: ${env.BUILD_URL}<br/>",
            to: 'test@server',                                
            attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}