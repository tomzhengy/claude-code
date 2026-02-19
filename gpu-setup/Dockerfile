FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

ENV DEBIAN_FRONTEND=noninteractive

# system deps
RUN apt-get update -qq && \
    apt-get install -y -qq \
        git curl jq build-essential openssh-server && \
    rm -rf /var/lib/apt/lists/*

# sshd setup
RUN mkdir -p /run/sshd && \
    echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config

# bun
RUN curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1
ENV BUN_INSTALL="/root/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1
ENV PATH="/root/.local/bin:$PATH"

# pipx
RUN pip install --no-cache-dir pipx > /dev/null 2>&1 && \
    pipx ensurepath > /dev/null 2>&1

# claude code (native installer, no node required)
RUN curl -fsSL https://claude.ai/install.sh | sh > /dev/null 2>&1

# copy scripts
COPY bootstrap.sh entrypoint.sh /opt/gpu-setup/
RUN chmod +x /opt/gpu-setup/*.sh

ENTRYPOINT ["/opt/gpu-setup/entrypoint.sh"]
