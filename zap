pipeline {
    agent any

    stages {
        stage("DAST Scan with OWASP ZAP") {
            steps {
                script {
                    echo '🔍 Running OWASP ZAP baseline scan...'

                    // Run the ZAP scan as root user
                    sh '''
                    docker run --rm --user root --network host -v $(pwd):/zap/wrk:rw \
                        -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                        -t http://127.0.0.1 \
                        -r zap_report.html -J zap_report.json
                    '''

                    // Parse the JSON report and fail the build if high severity alerts exist
                    if (fileExists('zap_report.json')) {
                        def zapJson = readJSON file: 'zap_report.json'
                        def highCount = zapJson.site.collect { it.alerts.findAll { it.risk == 'High' }.size() }.sum()
                        echo "High severity issues found: ${highCount}"

                        if (highCount > 0) {
                            error "ZAP detected High severity issues! Failing the build."
                        }
                    } else {
                        echo "ZAP JSON report not found, continuing build..."
                    }
                }
            }
            post {
                always {
                    echo '📦 Archiving ZAP scan reports...'
                    archiveArtifacts artifacts: 'zap_report.html,zap_report.json', allowEmptyArchive: true
                }
            }
        }
    }
}
