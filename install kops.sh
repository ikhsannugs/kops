#install kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
kubectl version

#install kops
curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops
sudo mv kops /usr/local/bin/kops
kops version

#install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws configure

#create s3 bucket
aws s3api create-bucket --bucket ikhsan-kops-state --region us-east-1
aws s3api put-bucket-versioning --bucket ikhsan-kops-state --region us-east-1 --versioning-configuration Status=Enabled

#create clusters
kops create cluster --name ikhsan.k8s.local --zones us-east-1a --master-size t2.medium --node-size t2.medium --ssh-public-key .ssh/authorized_keys --state s3://ikhsan-kops-state 
kops update cluster --name ikhsan.k8s.local --yes --admin --state s3://ikhsan-kops-state
kops validate cluster --wait 10m --state s3://ikhsan-kops-state
kops get cluster --state s3://ikhsan-kops-state

kops edit cluster --name ikhsan.k8s.local --state s3://ikhsan-kops-state
kops edit ig --name=ikhsan.k8s.local master-us-east-1a --state s3://ikhsan-kops-state
kops edit ig --name=ikhsan.k8s.local nodes-us-east-1a --state s3://ikhsan-kops-state
kops delete cluster --name ikhsan.k8s.local --state s3://ikhsan-kops-state --yes

kops rolling-update cluster --yes --state s3://ikhsan-kops-state

kops rolling-update cluster --force --cloudonly --yes

#SSH
https://github.com/kubernetes/kops/blob/master/docs/security.md
kops create sshpublickey --name ikhsan.k8s.local -i .ssh/authorized_keys --state s3://ikhsan-kops-state
kops update cluster --name ikhsan.k8s.local --yes --admin --state s3://ikhsan-kops-state
kops rolling-update cluster --yes --state s3://ikhsan-kops-state

#KubeConfig
kops export kubeconfig k8s-cluster.example.com --admin --state s3://ikhsan-kops-state

#Migrate High Available