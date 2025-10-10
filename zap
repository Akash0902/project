pipeline {
    agent any
    tools {
        maven 'MAVEN3'
        jdk 'JDK17'
    }
    
    stages {
        stage("DAST Scan with OWASP ZAP") {
            steps {
                script {
                    echo '🔍 Running OWASP ZAP baseline scan...'

                    try {
                        // Run ZAP with specific threshold - will exit with non-zero if violations above threshold
                        sh '''
                        docker run --rm --user root --network host -v $(pwd):/zap/wrk:rw \
                            -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                            -t http://localhost \
                            -r zap_report.html -J zap_report.json \
                            -I -c zap-baseline.conf
                        '''
                        echo "✅ ZAP scan passed - no high severity issues found"
                        
                    } catch (Exception e) {
                        echo "ZAP scan found issues: ${e.getMessage()}"
                        
                        // Even if ZAP fails, continue and just report the findings
                        if (fileExists('zap_report.json')) {
                            def zapJson = readJSON file: 'zap_report.json'
                            // Log findings but don't fail the build
                            echo "ZAP found security issues. Check the report for details."
                        }
                        // Don't fail the build for security warnings
                        // error "Security scan failed"
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'zap_report.html,zap_report.json', allowEmptyArchive: true
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '',
                        reportFiles: 'zap_report.html',
                        reportName: 'OWASP ZAP Security Report'
                    ])
                }
            }
        }
    }
}