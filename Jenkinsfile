pipeline {
  agent none
  triggers {
    cron('H 4 1,15 * *')
  }
  stages {
    stage('Build with Kaniko') {
      agent {
        kubernetes {
          label "kaniko"
          yaml """
kind: Pod
metadata:
  name: kaniko
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug-v0.17.1
    imagePullPolicy: Always
    command:
    - /busybox/cat
    tty: true
"""
        }
      }
      environment {
        PATH = "/busybox:/kaniko:$PATH"
      }
      steps {
        git branch: 'master',
            url: 'https://github.com/xcaliburinhand/ttrss-container.git'
        updateGithubCommitStatus name: 'build', state: 'pending'
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
          label "kaniko"
          yaml """
kind: Pod
metadata:
  name: kaniko
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
  post {
    success {
      updateGithubCommitStatus name: 'build', state: 'success'
    }
    failure {
      updateGithubCommitStatus name: 'build', state: 'failed'
    }
  }
}

def getRepoURL() {
  sh "git config --get remote.origin.url > .git/remote-url"
  return readFile(".git/remote-url").trim()
}
 
def getCommitSha() {
  sh "git rev-parse HEAD > .git/current-commit"
  return readFile(".git/current-commit").trim()
}
 
def updateGithubCommitStatus(build) {
  // workaround https://issues.jenkins-ci.org/browse/JENKINS-38674
  repoUrl = getRepoURL()
  commitSha = getCommitSha()
 
  step([
    $class: 'GitHubCommitStatusSetter',
    reposSource: [$class: "ManuallyEnteredRepositorySource", url: repoUrl],
    commitShaSource: [$class: "ManuallyEnteredShaSource", sha: commitSha],
    errorHandlers: [[$class: 'ShallowAnyErrorHandler']],
    statusResultSource: [
      $class: 'ConditionalStatusResultSource',
      results: [
        [$class: 'BetterThanOrEqualBuildResult', result: 'SUCCESS', state: 'SUCCESS', message: build.description],
        [$class: 'BetterThanOrEqualBuildResult', result: 'FAILURE', state: 'FAILURE', message: build.description],
        [$class: 'AnyBuildResult', state: 'PENDING', message: build.description]
      ]
    ]
  ])
}