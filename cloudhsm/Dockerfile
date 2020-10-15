FROM amazonlinux:latest AS build


RUN yum install -y wget && yum install -y awscli && yum install -y openssl && yum install -y jq
RUN wget https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/EL7/cloudhsm-client-latest.el7.x86_64.rpm
RUN yum install -y ./cloudhsm-client-latest.el7.x86_64.rpm

COPY init-cluster.sh /usr/bin/init-cluster.sh
WORKDIR /opt/cloudhsm

RUN chmod +x /usr/bin/init-cluster.sh
ENTRYPOINT /usr/bin/init-cluster.sh
