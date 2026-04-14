pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven'
    }

    environment {
        // Git
        REPO_URL = 'https://github.com/Akash0902/project.git'
        BRANCH   = 'main'

        // Sonar
        SONARQUBE_ENV     = 'sonar'
        SONAR_PROJECT_KEY = 'project'

        // Nexus
        NEXUS_CRED_ID  = 'nexus'
        NEXUS_REGISTRY = '15.206.166.35:8000'
        IMAGE_NAME     = 'project'

        // Kubernetes
        KUBECONFIG = '/var/lib/jenkins/kubeconfig'

        // Argo CD
        ARGOCD_SERVER   = '15.206.166.35:8082'
        ARGOCD_APP_NAME = 'project'

        // Automated version
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: "${BRANCH}", url: "${REPO_URL}"
            }
        }

        stage('Pre-Checks') {
            steps {
                sh '''
                echo "===== Docker check ====="
                docker ps

                echo "===== Kubernetes check ====="
                kubectl get nodes
                '''
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean test'
            }
        }

        stage('Publish JaCoCo Report') {
            steps {
                jacoco(
                    execPattern: 'target/*.exec',
                    classPattern: 'target/classes',
                    sourcePattern: 'src/main/java',
                    exclusionPattern: 'src/test*'
                )
            }
        }

        stage('Package WAR') {
            steps {
                sh 'mvn -DskipTests package'
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh "mvn sonar:sonar -Dsonar.projectKey=${SONAR_PROJECT_KEY}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build \
                  -t ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
                  -t ${NEXUS_REGISTRY}/${IMAGE_NAME}:latest .
                """
            }
        }

        stage('Push Image to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${NEXUS_CRED_ID}",
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh """
                    echo "${NEXUS_PASS}" | docker login ${NEXUS_REGISTRY} \
                      -u "${NEXUS_USER}" --password-stdin

                    docker push ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${NEXUS_REGISTRY}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Trigger Argo CD Sync') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'argocd',
                    usernameVariable: 'ARGOCD_USER',
                    passwordVariable: 'ARGOCD_PASS'
                )]) {
                    sh '''
                    set -e

                    /usr/local/bin/argocd login ${ARGOCD_SERVER} \
                      --username "$ARGOCD_USER" \
                      --password "$ARGOCD_PASS" \
                      --grpc-web \
                      --insecure

                    /usr/local/bin/argocd app sync ${ARGOCD_APP_NAME}
                    /usr/local/bin/argocd app wait ${ARGOCD_APP_NAME} --health --timeout 300
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                kubectl rollout restart deployment/project-deployment -n project
                kubectl rollout status deployment/project-deployment -n project --timeout=300s
                '''
            }
        }
    }

    post {
        always {
            sh 'docker image prune -f || true'
        }
    }
}
