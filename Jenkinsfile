pipeline {
    agent any

    parameters {
        string(name: 'TB_VERSION', defaultValue: '4.0', description: 'ThingsBoard version to upgrade to (e.g., 4.1)')
    }

    environment {
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

        stage('Build New Docker Image') {
            steps {
                echo "🔧 Building image ${IMAGE_NAME}"
                sh "docker build -t ${IMAGE_NAME} --build-arg TB_VERSION=${params.TB_VERSION} ."
            }
        }

        stage('Stop and Remove Old Container') {
            when {
                expression { env.CURRENT_VERSION != 'none' }
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
            steps {
                echo "🚀 Launching version ${params.TB_VERSION} using docker-compose"
                sh """
                    TB_VERSION=${params.TB_VERSION} docker compose down || true
                    TB_VERSION=${params.TB_VERSION} docker compose up -d
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '🔎 Verifying deployment...'
                sh "docker ps | grep ${CONTAINER_NAME}"
            }
        }
    }
}
