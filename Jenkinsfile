#!/bin/groovy
import jenkins.model.*
def deployToEnv(kube_context, environment) {
    timeout(time: 10, unit: 'MINUTES') {
        def files = findFiles(glob: 'envs/' + environment + '/*.yaml')
        script {
            env.KUBE_CONTEXT = kube_context
            env.ENVIRONMENT = environment
        }
            withCredentials([file(credentialsId: 'kube-config', variable: 'KUBECONFIG')]){
            for (i = 0; i < files.length; i++) {
                env.NAMESPACE_FILE = files[i].path
                sh "echo \"kubectl apply --context ${KUBE_CONTEXT} -f ${NAMESPACE_FILE}\""
                sh "kubectl apply --context ${KUBE_CONTEXT} -f ${NAMESPACE_FILE}"
            }
        }
    }
}
def validate() {
    timeout(time: 10, unit: 'MINUTES') {
        def files = findFiles(glob: '**/*.yaml')
        script {
            for (i = 0; i < files.length; i++) {
                    sh "kubectl apply --dry-run --validate -f ${files[i].path}"
            }
        }
    }
}


def tfApply(environment) {
     timeout(time: 10, unit: 'MINUTES') {
     dir('aws-infra/eu-west-2/' + environment + '/'){
             
             sh "terraform init"
             sh "terraform apply -auto-approve"
      }
  }
}


/***
 * Declarative pipeline starts here
***/
pipeline {
    agent any
    environment {
        userInput = true
        didTimeout = false
    }
    stages {

       stage('Dry run validate') {
           steps {
               script {
                   validate()
               }
           }
       }
       stage('Deploy to ENG') {
            when {
                branch 'master'
            }
            steps {
                script {
                    environment = 'eng'
                    lock_name = env.JOB_NAME + '-deploy-to-' + environment
                    kube_context = 'l2l.eu-west-2.eksctl.io'
                }

                lock( lock_name ) {
                    script {
                        deployToEnv(kube_context, environment)
                        tfApply(environment)
                    }
                }
            }
        }
        stage('Deploy notprod') {
            when {
                branch 'master'
            }
            steps {
                script {
                    environment = 'notprod'
                    lock_name = env.JOB_NAME + '-deploy-to-' + environment
                    kube_context = 'l2l.eu-west-2.eksctl.io'
                }

                lock( lock_name ) {
                    script {
                        deployToEnv(kube_context, environment)
                    }
                }
            }
        }

        stage('Deploy to PRD') {
            when {
                branch 'master'
            }
            steps {
                script {
                    userInput = input(
                    id: 'Proceed1', message: 'Deploy to Prod?', parameters: [
                    [$class: 'BooleanParameterDefinition', defaultValue: true, description: '', name: 'Please confirm you agree with this']
        ])
                    if (userInput == true) {
                        environment = 'prod'
                        lock_name = env.JOB_NAME + '-deploy-to-' + environment
                        kube_context = 'l2l.eu-west-2.eksctl.io'
                        lock( lock_name ) {
                            deployToEnv(kube_context, environment)
                        }
                    }
                }
            }
        }
    }
}

