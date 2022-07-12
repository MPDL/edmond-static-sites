pipeline {
    agent none
    environment {
       USERNAME = 'dataverse'
       REPO='edmond-sites'
    }
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '5', daysToKeepStr: '', numToKeepStr: '5')
        disableConcurrentBuilds()
    }
    stages {
        stage('unblock_key?') {
            agent none
            steps {
                echo "Last changes on ${BRANCH_NAME} will be deployed ..."

                script {
                    try {
                        timeout(time: 60, unit: 'SECONDS') {
                            env.UNBLOCK_KEY = input message: 'Please enter the API unblock key if you want to change settings',
                                parameters: [password(defaultValue: '', description: '', name: 'Password')]
                        }
                    } catch (err) {
                        env.UNBLOCK_KEY = ''
                    }                   
                }
            }
        }
        stage('dev') {
            agent any
            when {
                branch "dev"
            }
            environment {
                HOST="dev-edmond2.mpdl.mpg.de"
            }
            steps {
                echo "Waiting gracetime for optional unblock key ..."
                sleep(60)
                echo "... deploying to ${env.HOST}"

                script {                  
                    echo "Packaging ${env.REPO} to ${env.REPO}.zip"
                    sh('git archive -o $REPO.zip HEAD')

                    echo "Copying ${env.REPO}.zip to ${env.HOST} via scp"
                    sh('scp $REPO.zip $USERNAME@$HOST:/tmp/$REPO.zip')

                    echo "Unpackaging ${env.REPO}.zip on ${env.HOST}"
                    sh('ssh $USERNAME@$HOST "unzip -o -d /tmp/$REPO/ /tmp/$REPO.zip"')

                    echo "Starting deployment of ${REPO}"
                    if (env.UNBLOCK_KEY != '') {
                        sh('ssh ${USERNAME}@${HOST} "/tmp/${REPO}/deploy.sh -k $UNBLOCK_KEY"')
                    } else {
                        sh('ssh ${USERNAME}@${HOST} "/tmp/${REPO}/deploy.sh"')
                    }
                }
            }
        }
        stage('qa') {
            agent any
            when {
                branch "qa"
            }
            environment {
                HOST="qa-edmond2.mpdl.mpg.de"
            }
            steps {
                echo "Waiting gracetime for optional unblock key ..."
                sleep(60)
                echo "... deploying to ${env.HOST}"

                script {                  
                    echo "Packaging ${env.REPO} to ${env.REPO}.zip"
                    sh('git archive -o $REPO.zip HEAD')

                    echo "Copying ${env.REPO}.zip to ${env.HOST} via scp"
                    sh('scp $REPO.zip $USERNAME@$HOST:/tmp/$REPO.zip')

                    echo "Unpackaging ${env.REPO}.zip on ${env.HOST}"
                    sh('ssh $USERNAME@$HOST "unzip -o -d /tmp/$REPO/ /tmp/$REPO.zip"')

                    echo "Starting deployment of ${REPO}"
                    if (env.UNBLOCK_KEY != '') {
                        sh('ssh ${USERNAME}@${HOST} "/tmp/${REPO}/deploy.sh -k $UNBLOCK_KEY"')
                    } else {
                        sh('ssh ${USERNAME}@${HOST} "/tmp/${REPO}/deploy.sh"')
                    }
                }
            }
        }
        stage('prod') {
            agent any
            when {
                branch "prod"
            }
            environment {
                HOST="edmond.mpdl.mpg.de"
            }
            steps {
                echo "Waiting gracetime for optional unblock key ..."
                sleep(60)
                echo "... deploying to ${env.HOST}"

                script {                  
                    echo "Packaging ${env.REPO} to ${env.REPO}.zip"
                    sh('git archive -o $REPO.zip HEAD')

                    echo "Copying ${env.REPO}.zip to ${env.HOST} via scp"
                    sh('scp $REPO.zip $USERNAME@$HOST:/tmp/$REPO.zip')

                    echo "Unpackaging ${env.REPO}.zip on ${env.HOST}"
                    sh('ssh $USERNAME@$HOST "unzip -o -d /tmp/$REPO/ /tmp/$REPO.zip"')

                    echo "Starting deployment of ${REPO}"
                    if (env.UNBLOCK_KEY != '') {
                        sh('ssh ${USERNAME}@${HOST} "/tmp/${REPO}/deploy.sh -k $UNBLOCK_KEY"')
                    } else {
                        sh('ssh ${USERNAME}@${HOST} "/tmp/${REPO}/deploy.sh"')
                    }
                }
            }
        }
    }
}