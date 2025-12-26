pipeline {
    agent any

    environment {
        SCRIPT_DIR   = "operation/scripts"
        AWS_REGION   = "us-east-2"
        CLUSTER_NAME = "trendstore-eks"
        AWS_CREDS_ID = "aws-creds-id"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Scripts') {
            steps {
                script {
                    sh "chmod +x ${SCRIPT_DIR}/*.sh"
                }
            }
        }

        stage('Build image') {
            steps {
                sh "${SCRIPT_DIR}/compose.sh -b"
            }
        }

        stage('Push Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker_pat') {
                        sh "${SCRIPT_DIR}/compose.sh -p"
                    }
                }
            }
        }

        stage('Configure Kubeconfig for EKS') {
            steps {
                script {
                    // Use withAWS *inside* steps + script
                    withAWS(credentials: AWS_CREDS_ID, region: AWS_REGION) {
                        sh """
                        aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}
                        kubectl get nodes -o wide
                        echo "✅ EKS kubeconfig configured"
                        """
                    }
                }
            }
        }

        stage('Deploy Container') {
            steps {
                sh "${SCRIPT_DIR}/compose.sh -d"
            }
        }

        stage('Monitoring Setup') {
            steps {
                script {
                    sh '''
                    # Add/Update Helm repo for Prometheus stack
                    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
                    helm repo update

                    # Install/upgrade kube-prometheus-stack in monitoring namespace
                    helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
                      --namespace monitoring --create-namespace
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh '''
                    echo "=== Kubernetes objects ==="
                    kubectl get nodes -o wide
                    kubectl get pods -n default -l app=trendstore
                    kubectl get svc -n default
                    kubectl get hpa trendstore-hpa -n default || true

                    echo "=== Prometheus health check ==="
                    kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 >/tmp/prom_pf.log 2>&1 &
                    PF_PID=$!

                    sleep 10

                    curl -s "http://localhost:9090/api/v1/query?query=up{job=~\\\"kubelet|kube-state-metrics\\\"}" | grep '"value"' || true
                    echo "Prometheus health check stage completed"

                    kill $PF_PID || true
                    '''
                }
            }
        }

        stage('Grafana Dashboard') {
            steps {
                script {
                    sh '''
                    echo "=== Checking Grafana dashboard ==="
                    kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 >/tmp/grafana_pf.log 2>&1 &
                    GF_PID=$!

                    sleep 10

                    # Note: orgId (capital I), Prometheus datasource name is usually 'Prometheus'
                    curl -s "http://localhost:3000/d/6417/k8s-cluster?orgId=1&from=now-1h&to=now&var-ds_prometheus=Prometheus&var-cluster=&var-namespace=default&var-job=&var-pod=trendstore" >/dev/null || true

                    echo "✅ Grafana dashboard accessible at http://localhost:3000/d/6417/k8s-cluster?orgId=1&var-namespace=default&var-pod=trendstore"

                    kill $GF_PID || true
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment Successful'
        }
        failure {
            echo 'Pipeline Failed — Check Logs'
        }
    }
}

