pipeline {
  agent none
  triggers {
    cron('H 4 1,15 * *')
  }
  stages {
    stage('Build with Kaniko') {
      agent {
        kubernetes {
          inheritFrom "kaniko"
        }
      }
      environment {
        PATH = "/busybox:/kaniko:$PATH"
      }
      steps {
        git branch: 'master',
            url: 'https://github.com/xcaliburinhand/ttrss-container.git'
        container(name: 'kaniko', shell: '/busybox/sh') {
            sh '''#!/busybox/sh
            /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --skip-tls-verify --destination=containers.internal/ttrss:latest
           '''
        }
      }
    }
    stage('Deploy') {
      agent {
        kubernetes {
          yaml """
kind: Pod
metadata:
  name: kubectl
spec:
  serviceAccount: jenkins
  containers:
  - name: kubectl
    image: containers.internal/kubectl:latest
    imagePullPolicy: Always
    command:
    - sh
    args:
    - -c
    - cat
    tty: true
"""
        }
      }
      steps {
        container(name: 'kubectl', shell: '/bin/sh') {
            sh '''#!/bin/sh
            kubectl delete pods -l app=ttrss -n muteheadlight
            '''
        }
      }
    }
  }
}
