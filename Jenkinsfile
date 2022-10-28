def do_deploy() {
                echo "Waiting gracetime for optional answers: \nkey for settings update (default is not update), \nSKIP guides updates (default is not SKYP), \nupdate branding (default is not update) \n..."
                sleep(120)
                echo "... deploying ${BRANCH_NAME}"

                script {                  
                    if (env.UNBLOCK_KEY) {
                        echo "Starting settings update"
                        sh('ssh ${USERNAME}@${TARGET_HOST} "/tmp/${REPO}/updateSettings.sh -k $UNBLOCK_KEY -d $DOCROOT"')
                    } else {
                        echo "Packaging to zip"
                        sh('git archive -o $REPO.zip HEAD')

                        echo "Copying zip to destination host"
                        sh('scp $REPO.zip $USERNAME@$TARGET_HOST:/tmp/$REPO.zip')

                        echo "Unpackaging zip on destination"
                        sh('ssh $USERNAME@$TARGET_HOST "unzip -o -d /tmp/$REPO/ /tmp/$REPO.zip"')

                        echo "Starting deployment"
                        if (env.DO_GUIDES) {
                            sh('ssh ${USERNAME}@${TARGET_HOST} "/tmp/${REPO}/deployGuides.sh -d $DOCROOT"')
                        }
                        if (env.DO_BRANDING) {
                            sh('ssh ${USERNAME}@${TARGET_HOST} "/tmp/${REPO}/deployBranding.sh -d $DOCROOT"')
                        }
                        echo "Cleaning temporary files"
                        sh('ssh $USERNAME@$TARGET_HOST "rm -rf /tmp/${REPO} /tmp/$REPO.zip"')
                    }
                }
}

pipeline {
    agent none
    environment {
       USERNAME= credentials("edmond-static-user") 
       REPO= credentials("edmond-static-repo") 
       DOCROOT= credentials("edmond-static-docroot") 
    }
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '5', daysToKeepStr: '', numToKeepStr: '5')
        disableConcurrentBuilds()
    }
    stages {
        stage('optional_api_unblock_key?') {
            agent none
            steps {
                echo "Last settings on ${BRANCH_NAME} could be updated ..."

                script {
                    try {
                        timeout(time: 60, unit: 'SECONDS') {
                            env.UNBLOCK_KEY = input message: 'Please enter the API unlock key if you want to change the settings (waiting for a limited time for your response, otherwise the settings remain unchanged)',
                                parameters: [password(defaultValue: '', description: '', name: 'API Key?')]
                        }
                    } catch (err) {
                        env.UNBLOCK_KEY = ''
                    }                   
                }
            }
        }
        stage('optional_skip_guides?') {
            agent none
            steps {
                echo "Last content changes on ${BRANCH_NAME} will be deployed ..."

                script {
                    try {
                        timeout(time: 30, unit: 'SECONDS') {
                            env.DO_GUIDES = input message: 'Guides updates are deployed per default, do you want to SKIP this? (default is Not)',
                            ok: 'Yes', 
                            parameters: [booleanParam(defaultValue: false, description: 'To confirm, just push the button',name: 'SKIP?')] 
                        }
                    } catch (err) {
                        env.DO_GUIDES = true
                    }          
                }
            }
        }
        stage('optional_update_branding?') {
            agent none
            steps {
                echo "Last branding changes on ${BRANCH_NAME} could be deployed ..."

                script {
                    try {
                        timeout(time: 30, unit: 'SECONDS') {
                            env.DO_BRANDING = input message: 'Do you want to deploy Branding updates? (default is Not)', 
                            ok: 'Yes', 
                            parameters: [booleanParam(defaultValue: false, description: 'To confirm, just push the button',name: 'Deploy?')] 
                        }
                    } catch (err) {
                        env.DO_BRANDING = false
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
                TARGET_HOST = credentials("edmond-${env.BRANCH_NAME}-host")
            }
            steps {
                do_deploy();
            }
        }
        stage('qa') {
            agent any
            when {
                branch "qa"
            }
            environment {
                TARGET_HOST = credentials("edmond-${env.BRANCH_NAME}-host")
            }
            steps {
                do_deploy();
            }
        }
        stage('live') {
            agent any
            when {
                branch "live"
            }
            environment {
                TARGET_HOST = credentials("edmond-${env.BRANCH_NAME}-host")
            }
            steps {
                do_deploy();
            }
        }
    }
}