pipeline {
    agent any

    stages {
        stage("DAST Scan with OWASP ZAP") {
            steps {
                script {
                    echo '🔍 Running OWASP ZAP baseline scan...'

                    // Run ZAP scan but ignore exit code
                    sh '''
                    set +e
                    docker run --rm --user root --network host -v $(pwd):/zap/wrk:rw \
                        -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                        -t http://localhost \
                        -r zap_report.html -J zap_report.json
                    '''

                    // Read report if it exists
                    if (fileExists('zap_report.json')) {
                        def zapJson = readJSON file: 'zap_report.json'
                        def highCount = zapJson.site.collect { it.alerts.findAll { it.risk == 'High' }.size() }.sum()
                        def warnCount = zapJson.site.collect { it.alerts.findAll { it.risk == 'Medium' || it.risk == 'Low' }.size() }.sum()

                        echo "✅ High severity issues: ${highCount}"
                        echo "⚠️ Warning / Medium / Low issues: ${warnCount}"
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
