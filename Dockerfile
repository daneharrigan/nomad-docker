FROM golang:1.14.2 AS build
MAINTAINER Dane Harrigan <dane.harrigan@gmail.com>

ENV NOMAD_VERSION=v0.11.1
ENV CONSUL_VERSION=1.7.2
ENV CNI_VERSION=v0.8.5

RUN apt-get update -y && apt-get install -y curl unzip

RUN \
  export HASHICORP_PATH=$GOPATH/src/github.com/hashicorp && \
  mkdir -p $HASHICORP_PATH && \
  git clone -b ${NOMAD_VERSION} --depth 1 https://github.com/hashicorp/nomad $HASHICORP_PATH/nomad && \
  go build -tags nonvidia -o /tmp/nomad github.com/hashicorp/nomad

RUN \
  echo "" > /etc/sysctl.d/iptables-bridge.conf && \
  echo "net.bridge.bridge-nf-call-arptables = 1" >> /etc/sysctl.d/iptables-bridge.conf && \
  echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/iptables-bridge.conf && \
  echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/iptables-bridge.conf

RUN \
  export CNI_URL="https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" && \
  curl -sSL --retry 5 --output /tmp/cni.tgz "${CNI_URL}" && \
  mkdir -p /opt/cni/bin && \
  tar -C /opt/cni/bin -xzf /tmp/cni.tgz

RUN \
  export CONSUL_URL=https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip && \
  curl -sSL --retry 5 --output /tmp/consul.zip "${CONSUL_URL}" && \
  unzip /tmp/consul.zip -d /tmp

FROM alpine:3.11

COPY --from=build /etc/sysctl.d/iptables-bridge.conf /etc/sysctl.d/iptables-bridge.conf
COPY --from=build /opt/cni/bin /opt/cni/bin
COPY --from=build /tmp/nomad /usr/bin/nomad
COPY --from=build /tmp/consul /usr/bin/consul

RUN mkdir -p /nomad/data /nomad/config

RUN apk update && apk add libc6-compat iptables ip6tables iputils ca-certificates

VOLUME /nomad/data

EXPOSE 4646

ENTRYPOINT ["/usr/bin/nomad"]
CMD ["agent", "-dev-connect", "-config=/nomad/config", "-bind=0.0.0.0", "-retry-join=0.0.0.0"]
