FROM ubuntu:latest

# Set environment variables to avoid user interaction during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    gnupg \
    software-properties-common \
    unzip

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && \
    apt-get install -y terraform

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Create a new user
RUN groupadd -r tf && useradd -r -g tf tf

# Create necessary directories
RUN mkdir /code
RUN mkdir /home/tf
RUN chown -R tf:tf /home/tf

# Switch to the new user
USER tf

# Set some helper Bash aliases to make life easier
RUN echo "alias azl='az login'" >> /home/tf/.bashrc
RUN echo "alias ti='terraform init'" >> /home/tf/.bashrc
RUN echo "alias tp='terraform plan -refresh=true -out=terraform.tfplan'" >> /home/tf/.bashrc
RUN echo "alias ta='terraform apply terraform.tfplan'" >> /home/tf/.bashrc
RUN echo "alias tr='rm -rf .terraform terraform.tfplan terraform.tfstate* .terraform.lock.hcl'" >> /home/tf/.bashrc

# Verify installations
RUN terraform --version && az --version

# Set the default entrypoint
WORKDIR /code/terraform
CMD ["bash"]
