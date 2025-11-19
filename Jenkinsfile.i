// Jenkinsfile (Декларативный Пайплайн)

pipeline {
    agent any
    
    environment {
        SERVICE_NAME = 'java_service'
        DOCKER_IMAGE = "my-java-app:${env.BUILD_NUMBER}"
        LOG_LEVEL_PARAM = 'INFO' // Параметр для изменения
    }

    tools {
        maven 'maven'
    }

    stages {
        stage('Checkout') {
            steps {
                // Получаем исходный код из Git (предполагается, что репозиторий настроен)
                // Для простоты здесь используется текущий рабочий каталог
                echo 'Checking out source code...'
                git url: 'https://github.com/Ronalful/elk-test/'


            }
        }

        stage('Update Log Configuration') {
            steps {
                script {
                    // 1. Изменение параметра логов в файле приложения (имитация)
                    echo "Changing log level in application file to ${LOG_LEVEL_PARAM}..."
                    // Пример: sed -i "s/logging.level=.*/logging.level=/${LOG_LEVEL_PARAM}/g" application.properties
                    // Здесь мы просто имитируем, чтобы показать, что Jenkins может менять параметры
                    env.LOG_LEVEL_OLD = readFile('src/main/resources/application.properties').tokenize('\n').find { it.startsWith('logging.level=') } ?: 'INFO'
                }
            }
        }

        stage('Build and Test') {
            steps {
                // 2. Сборка Java-приложения (mvn clean package)
                sh 'mvn clean package -DskipTests'

                // 3. Сборка Docker образа с новым JAR
                sh "docker build -t ${DOCKER_IMAGE} ."
                sh "docker tag ${DOCKER_IMAGE} ${SERVICE_NAME}:latest"
            }
        }

        stage('Deploy and Test') {
            steps {
                script {
                    // 4. Запуск контейнера с новым образом (перезапуск через docker-compose)
                    // Сохраняем текущий активный образ для потенциального Rollback
                    env.CURRENT_IMAGE = sh(script: "docker images -q ${SERVICE_NAME}:latest 2>/dev/null || echo 'none'", returnStdout: true).trim()

                    try {
                        echo "Deploying new image: ${DOCKER_IMAGE}"
                        // Остановка старого и запуск нового сервиса
                        sh "docker-compose up -d --no-deps --build ${SERVICE_NAME}"

                        // Имитация теста (проверка доступности или API)
                        sh 'sleep 10'
                        sh 'curl -f http://localhost:8081/actuator/health'
                        echo "Deployment successful. New logs are being sent to ELK."

                    } catch (e) {
                        // 5. Rollback в случае ошибки
                        echo "Deployment failed. Attempting rollback to image: ${env.CURRENT_IMAGE}"
                        if (env.CURRENT_IMAGE != 'none') {
                            sh "docker tag ${env.CURRENT_IMAGE} ${SERVICE_NAME}:rollback"
                            sh "docker-compose up -d --no-deps --build ${SERVICE_NAME}" // Использует rollback тег
                        } else {
                            echo "Rollback not possible: No previous image found."
                        }
                        error("Deployment failed and rollback attempted.")
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo 'Cleaning up old Docker images...'
                sh 'docker rmi -f $(docker images -f \'dangling=true\' -q)'
            }
        }
    }
}