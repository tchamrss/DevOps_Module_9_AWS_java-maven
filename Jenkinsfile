#!/usr/bin/env groovy

library identifier: 'jenkins-shared-library-aws@master', retriever: modernSCM(
    [$class: 'GitSCMSource',
    remote: 'https://github.com/tchamrss/jenkins-shared-library-aws.git',
    credentialsId: 'git-credential'
    ]
)

pipeline {
    agent any
    tools {
        maven 'Maven'
    }
    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_NAME = "tchamrss/react-nodejs-example:$version-$BUILD_NUMBER"
                }
            }
        }
        stage('build app') {
            steps {
                echo 'building application jar...'
                buildJar()
            }
        }
        stage('build image') {
            steps {
                script {
                    echo 'building the docker image...'
                    buildImage(env.IMAGE_NAME)
                    dockerLogin()
                    dockerPush(env.IMAGE_NAME)
                }
            }
        } 
        stage("deploy") {
            steps {
                script {
                    echo 'deploying docker image to EC2...'

                    def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME}"
                    def ec2Instance = "ec2-user@56.228.22.129"

                    sshagent(['ec2-server-key-new']) {
                        sh "scp server-cmds.sh ${ec2Instance}:/home/ec2-user"
                        sh "scp docker-compose.yaml ${ec2Instance}:/home/ec2-user"
                        sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
                    }
                }
            }               
        }
        stage('commit version update') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'git-push-credential',
                            usernameVariable: 'GIT_USER',
                            passwordVariable: 'GIT_TOKEN'
                        )
                    ]) {
                        sh '''
                            set +x
                            git add pom.xml .gitignore

                            if ! git diff --cached --quiet; then
                                git -c user.name="Jenkins" \
                                    -c user.email="jenkins@localhost" \
                                    commit -m "ci: version bump"
                            fi

                            AUTH=$(printf '%s:%s' "$GIT_USER" "$GIT_TOKEN" | base64 | tr -d '\\n')
                            git -c http.extraheader="AUTHORIZATION: basic $AUTH" \
                                push origin HEAD:jenkins-jobs
                        '''
                    }
                }
            }
        }
    }
}
