pipeline {
    agent any

    parameters {
        string(name: 'TB_VERSION', defaultValue: '4.0', description: 'ThingsBoard version to upgrade to (e.g., 4.1)')
    }

    environment {
        PACKAGE_REPO  = "https://github.com/thingsboard/thingsboard/releases/download"
        IMAGE_NAME = "thingsboard:${params.TB_VERSION}"
        CONTAINER_NAME = "thingsboard-${params.TB_VERSION}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out repository...'
                checkout scm
            }
        }

        stage('Detect Current Installed Version') {
            steps {
                script {
                    echo '🔍 Detecting current running ThingsBoard container...'
                    def running = sh(script: "docker ps --format '{{.Names}}' | grep ${CONTAINER_NAME} || true", returnStdout: true).trim()

                    if (running) {
                        def currentImage = sh(script: "docker inspect ${CONTAINER_NAME} --format '{{ index .Config.Image }}'", returnStdout: true).trim()
                        def currentTag = currentImage.split(":")[1]
                        echo "📦 Current running version: ${currentTag}"
                        env.CURRENT_VERSION = currentTag
                    } else {
                        echo "⚠️ No running ThingsBoard container named ${CONTAINER_NAME}"
                        env.CURRENT_VERSION = "none"
                    }
                }
            }
        }


        stage('Compare Versions') {
            steps {
                script {
                    echo '🔍 Comparing current version with latest release...'
                    if (!env.CURRENT_VERSION || !env.TB_VERSION) {
                        error '❌ Cannot compare versions — one or both are unknown!'
                    }
                    echo "📦 Current version: ${env.CURRENT_VERSION}, Latest version: ${env.TB_VERSION}"
                    // Compare versions
                    if (env.CURRENT_VERSION == env.TB_VERSION) {
                        // If versions match, skip upgrade
                        echo "✅ ThingsBoard is already up to date (v${env.CURRENT_VERSION})"
                        env.UPGRADE_REQUIRED = "false"
                    } else {
                        // If versions differ, set upgrade required
                        echo "⬆️ Upgrade required: ${env.CURRENT_VERSION} ➜ ${env.TB_VERSION}"
                        env.UPGRADE_REQUIRED = "true"
                    }
                }
            }
        }


        stage('Skip Upgrade') {
            when {
                expression { env.UPGRADE_REQUIRED == "false" }
            }
            steps {
                echo "✅ Skipping upgrade — Already latest version."
            }
        }

        
        stage('Download RPM') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    echo "📥 Downloading ThingsBoard RPM package..."
                    // Construct the RPM URL based on the latest version
                    def rpmUrl = "${PACKAGE_REPO}/v${env.TB_VERSION}/thingsboard-${env.TB_VERSION}.rpm"
                    echo "📥 Downloading RPM from: ${rpmUrl}"
                    // Download the RPM package
                    sh """
                        curl -L -o thingsboard-${env.TB_VERSION}.rpm ${rpmUrl}
                        ls -lh thingsboard-*.rpm
                    """
                }
            }
        }

        stage('Build New Docker Image') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                echo "🔧 Building image ${IMAGE_NAME}"
                sh "docker build -t ${IMAGE_NAME} --build-arg TB_VERSION=${params.TB_VERSION} ."
            }
        }

        stage('Stop and Remove Old Container') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
           
            steps {
                echo "🛑 Stopping container ${CONTAINER_NAME}"
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                """
            }
        }

        stage('Start New Version with Docker Compose') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                echo "🚀 Launching version ${params.TB_VERSION} using docker-compose"
                sh """
                    TB_VERSION=${params.TB_VERSION} docker compose down || true
                    TB_VERSION=${params.TB_VERSION} docker compose up -d
                """
            }
        }

        stage('Verify Deployment') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    echo "🔍 Verifying ThingsBoard is running"
                    // Wait for ThingsBoard to start up
                    sleep 60
                    sleep 60
                    echo '🔎 Verifying deployment...'
                    sh "docker ps | grep ${CONTAINER_NAME}"
    
                    echo "🔍 Verifying application is up"
                        // Check if ThingsBoard is responding on HTTP
                    def code = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/login", returnStdout: true).trim()
                    if (code != "200") {
                        echo "❌ ThingsBoard is not responding correctly (HTTP ${code})"
                        // If not 200, fail the build
                        error "❌ Upgrade failed — HTTP status: ${code}"
                    } else {
                        // If 200, everything is fine
                        echo "✅ ThingsBoard is up and responding (HTTP 200)"
                    }
                }
            }
        }
    }
    post {
        success {
            script {
                echo "✅ Upgrade pipeline completed successfully!"
                // Print final version information
                echo "Current version: ${env.TB_VERSION}"
                // Check if an upgrade was performed
                if (env.UPGRADE_REQUIRED == "true") {
                    echo "🎉 ThingsBoard upgraded from v${env.CURRENT_VERSION} to v${env.Tb_VERSION} successfully!"

                } else {
                    echo "✅ No upgrade needed. Still running v${env.CURRENT_VERSION}."

                }
            }
        }
        failure {
            echo "❌ ThingsBoard upgrade failed!"
        }
        unstable {
            echo "⚠️ ThingsBoard upgrade is unstable!"
        }

    }
}
