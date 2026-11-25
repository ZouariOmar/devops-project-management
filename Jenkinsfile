// =================================================================================
// .FILE
//   Jenkinsfile
//
// .SYNOPSIS
//   CI pipeline of the project
//
// .DESCRIPTION
//   Builds and tests the Spring Boot backend and the Angular frontend, then
//   archives the backend JAR.
//
// .USAGE
//   Run by the Jenkins pipeline job.
//
// .PARAMETER
//   N/A
//
// .INPUTS
//   Jenkins credential `mysql-credentials` and variable MYSQL_URL.
//
// .OUTPUTS
//   Build status and the archived JAR.
//
// .NOTES
//   Version       : 1.0
//   Author        : @ZouariOmar (zouariomar20@gmail.com)
//   Created       : 2026-11-24
//   Changelog     : e1e38b7
// =================================================================================

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
                            usernameVariable: 'MYSQL_USER',
                            passwordVariable: 'MYSQL_PASSWORD'
                        )
                    ]) {
                        sh '''
                            echo "Running backend tests..."
                            echo "Database: $MYSQL_URL"

                            ./mvnw test
                        '''
                    }
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('project/frontend') {
                    sh '''
                        npm ci
                        npm run build
                    '''
                }
            }
        }

        stage('Test Frontend') {
            steps {
                dir('project/frontend') {
                    sh 'npm test -- --watch=false'
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
