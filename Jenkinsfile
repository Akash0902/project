def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger',
]

pipeline {
    agent any
    tools {
        maven 'MAVEN3'
        jdk 'JDK17'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        NEXUS_VERSION = 'nexus3'
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "192.168.64.6:8081"
        NEXUS_REPOSITORY = "vprofile-repo"
        NEXUS_REPO_ID = "vprofile-repo"
        NEXUS_CREDENTIAL_ID = "nexuslogin"
        ARTVERSION = "${env.BUILD_ID}"

        DOCKER_NAME  = 'harishnshetty/vprofile'
        IMAGE_NAME   = 'vprofile'
        
    }
    
    stages {
        stage("Clean Workspace") {
            steps {
                cleanWs()
            }
        }

        stage("Git Checkout") {
            steps {
                git branch: 'main', url: 'https://github.com/harishnshetty/maven-devsecops-ecr-project.git'
            }
        }

        stage('BUILD') {
            steps {
                sh 'mvn clean install -DskipTests'
            }
            post {
                success {
                    echo 'Now Archiving...'
                    archiveArtifacts artifacts: '**/target/*.war'
                }
            }
        }

        // stage('UNIT TEST') {
        //     steps {
        //         sh 'mvn test'
        //     }
        // }

        // stage('INTEGRATION TEST') {
        //     steps {
        //         sh 'mvn verify -DskipUnitTests'
        //     }
        // }
        
        // stage('CODE ANALYSIS WITH CHECKSTYLE') {
        //     steps {
        //         sh 'mvn checkstyle:checkstyle'
        //     }
        //     post {
        //         success {
        //             echo 'Generated Analysis Result'
        //         }
        //     }
        // }

        // stage('CODE ANALYSIS with SONARQUBE') {
        //     steps {
        //         withSonarQubeEnv('sonar-server') {
        //             sh '''${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectKey=vprofile \
        //                 -Dsonar.projectName=vprofile-repo \
        //                 -Dsonar.projectVersion=1.0 \
        //                 -Dsonar.sources=src/ \
        //                 -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
        //                 -Dsonar.junit.reportsPath=target/surefire-reports/ \
        //                 -Dsonar.jacoco.reportsPath=target/jacoco.exec \
        //                 -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
        //         }
        //         timeout(time: 10, unit: 'MINUTES') {
        //             waitForQualityGate abortPipeline: true
        //         }
        //     }
        // }

        // stage("Publish to Nexus Repository Manager") {
        //     steps {
        //         script {
        //             pom = readMavenPom file: "pom.xml"
        //             filesByGlob = findFiles(glob: "target/*.${pom.packaging}")
        //             echo "${filesByGlob[0].name} ${filesByGlob[0].path} ${filesByGlob[0].directory} ${filesByGlob[0].length} ${filesByGlob[0].lastModified}"
        //             artifactPath = filesByGlob[0].path
        //             artifactExists = fileExists artifactPath
        //             if(artifactExists) {
        //                 echo "*** File: ${artifactPath}, group: ${pom.groupId}, packaging: ${pom.packaging}, version ${pom.version} ARTVERSION"
        //                 nexusArtifactUploader(
        //                     nexusVersion: NEXUS_VERSION,
        //                     protocol: NEXUS_PROTOCOL,
        //                     nexusUrl: NEXUS_URL,
        //                     groupId: pom.groupId,
        //                     version: ARTVERSION,
        //                     repository: NEXUS_REPOSITORY,
        //                     credentialsId: NEXUS_CREDENTIAL_ID,
        //                     artifacts: [
        //                         [artifactId: pom.artifactId,
        //                         classifier: '',
        //                         file: artifactPath,
        //                         type: pom.packaging],
        //                         [artifactId: pom.artifactId,
        //                         classifier: '',
        //                         file: "pom.xml",
        //                         type: "pom"]
        //                     ]
        //                 )
        //             } else {
        //                 error "*** File: ${artifactPath}, could not be found"
        //             }
        //         }
        //     }
        // }

        // stage("OWASP FS Scan") {
        //     steps {
        //         dependencyCheck additionalArguments: '''
        //             --scan . 
        //             --disableYarnAudit 
        //             --disableNodeAudit 
        //         ''',
        //         odcInstallation: 'dp-check'
        //         dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        //     }
        // }

        // stage("Trivy File Scan") {
        //     steps {
        //         sh "trivy fs . > trivyfs.txt"
        //     }
        // }

        stage("Build Docker Image") {
            steps {
                script {
                    env.IMAGE_TAG = "$DOCKER_NAME:${BUILD_NUMBER}"
                    sh "docker rmi -f $IMAGE_NAME ${env.IMAGE_TAG} || true"
                    sh "docker build -t $IMAGE_NAME ."
                    sh "docker tag $IMAGE_NAME ${env.IMAGE_TAG}"
                    sh "docker tag $IMAGE_NAME $DOCKER_NAME:latest"
                    
                }
            }
        }

        // stage("Tag & Push to DockerHub") {
        //     steps {
        //         script {
        //             withCredentials([string(credentialsId: 'docker-cred', variable: 'dockerpwd')]) {
        //                 sh "docker login -u harishnshetty -p ${dockerpwd}"
        //                 sh "docker tag vprofile ${env.IMAGE_TAG}"
        //                 sh "docker push ${env.IMAGE_TAG}"
        //                 sh "docker tag vprofile harishnshetty/vprofile:latest"
        //                 sh "docker push harishnshetty/vprofile:latest"
        //             }
        //         }
        //     }
        // }

        stage("Trivy Scan Image") {
            steps {
                script {
                    sh """
                    echo '🔍 Running Trivy scan on ${env.IMAGE_TAG}'
                    trivy image -f json -o trivy-image.json ${env.IMAGE_TAG}
                    trivy image -f table -o trivy-image.txt ${env.IMAGE_TAG}
                    """
                }
            }
        }
        stage('Upload App Image to ECR') {
            steps {
                script {
                    docker.withRegistry('', 'registryCredential') {
                        docker.image("harishnshetty/vprofile:${BUILD_NUMBER}").push("$BUILD_NUMBER")
                        docker.image("harishnshetty/vprofile:${BUILD_NUMBER}").push("latest")
                    }
                }
            }
        }

        stage("Deploy to Container") {
            steps {
                script {
                    sh "docker rm -f vprofile || true"
                    sh "docker run -d --name vprofile -p 80:8080 ${env.IMAGE_TAG}"
                }
            }
        }


    }
    
    post {
        always {
            echo 'Slack Notification'
            slackSend channel: '#devopscicd',
            color: COLOR_MAP[currentBuild.currentResult],
            message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More Info At: ${env.BUILD_URL}"
        }
    }
}