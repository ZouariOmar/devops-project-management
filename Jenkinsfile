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
        pollSCM('H/2 * * * *')
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
                        chmod +x mvnw
                        ./mvnw clean package -DskipTests
                    '''
                }
            }
        }

        stage('Test Backend') {
            steps {
                dir('project/backend') {
                    sh './mvnw test'
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
