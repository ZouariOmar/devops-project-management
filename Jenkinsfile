pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(
            numToKeepStr: '10',
            artifactNumToKeepStr: '5'
        ))
    }

    triggers {
        githubPush()
    }

    environment {
        DB_URL = "${DB_URL}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Backend') {
            steps {
                dir('project/backend') {
                    sh '''
                        chmod u+x mvnw
                        ./mvnw clean package -DskipTests
                    '''
                }
            }
        }

        stage('Test Backend') {
            steps {
                dir('project/backend') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'mysql-credentials',
                            usernameVariable: 'DB_USER',
                            passwordVariable: 'DB_PASSWORD'
                        )
                    ]) {
                        sh '''
                            echo "Running backend tests..."
                            echo "Database: $DB_URL"

                            ./mvnw test
                        '''
                    }
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('project/frontend') {
                    sh 'npm r build'
                }
            }
        }

        stage('Test Frontend') {
            steps {
                dir('project/frontend') {
                    sh 'npm r test'
                }
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts(
                    artifacts: 'project/backend/target/*.jar',
                    fingerprint: true
                )
            }
        }
    }

    post {
        success {
            echo 'Build completed successfully!'
        }

        failure {
            echo 'Build failed. Check the pipeline logs.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
