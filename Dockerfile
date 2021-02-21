ARG TERRAFORM_VERSION=0.12.24
FROM 496557256474.dkr.ecr.eu-west-2.amazonaws.com/saas-jnlp-slave:latest
ARG user=jenkins
USER root
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/linux/amd64/kubectl; mv kubectl  /usr/local/bin/kubectl; 
RUN chmod 555 /usr/local/bin/kubectl;
RUN curl -sfSL https://releases.hashicorp.com/terraform/0.11.0/terraform_0.11.0_linux_amd64.zip > terraform.zip; unzip terraform.zip -d /usr/local/bin; rm -f terraform.zip;
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; unzip awscliv2.zip; ./aws/install; rm -rf awscliv2.zip;
ENV HELM_VERSION="v3.2.4"
RUN wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm
RUN apt update -y
RUN apt install -y less
RUN apt install -y jq
#USER jenkins
