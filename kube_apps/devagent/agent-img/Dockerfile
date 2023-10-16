FROM --platform=linux/amd64 ubuntu:22.04

RUN apt update \
    && apt upgrade -y \
    && useradd -m agentuser \
    && apt install -y --no-install-recommends \
    ca-certificates wget \
    unzip curl git jq libicu70 \
    # Install helm \
    && curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh \
    # Install kubectl \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    # Install terraform \
    && curl -LO "https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip"  \
    && unzip terraform_1.5.7_linux_amd64.zip \
    && mv terraform /usr/bin/terraform \
    && rm terraform_1.5.7_linux_amd64.zip get_helm.sh \
    # Instal zdo-agent \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Also can be "linux-arm", "linux-arm64".
ENV TARGETARCH="linux-x64"

WORKDIR /azp/
RUN chown -R agentuser:agentuser /azp
RUN chmod 755 /azp

COPY ./start.sh ./
RUN chmod +x ./start.sh
USER agentuser

ENTRYPOINT [ "./start.sh", "--once" ]