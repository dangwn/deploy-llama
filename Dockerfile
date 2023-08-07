FROM ubuntu:20.04 AS build-image

ARG DEBIAN_FRONTEND=noninterative

RUN apt-get -y update && apt-get upgrade -y
RUN apt-get install -y curl

# Install python
RUN apt-get install --no-install-recommends -y python3.9 \
    python3-dev \
    python3-venv \
    python3-pip \
    python3-wheel 

# Create virtual env
RUN python3 -m venv /home/appuser/venv
ENV PATH="/home/appuser/venv/bin:$PATH"

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install requirements
COPY ./llama llama
# COPY ./requirements.txt requirements.txt
RUN pip3 install --no-cache-dir wheel
RUN pip3 install --no-cache-dir --upgrade pip
# RUN pip3 install --no-cache-dir --default-timeout=900 -r requirements.txt

# Run image
FROM ubuntu:20.04 AS run-image

ARG DEBIAN_FRONTEND=noninterative
ARG API_PORT="8080"
ARG API_HOST="0.0.0.0"

ENV API_PORT=${API_PORT}
ENV API_HOST=${API_HOST}

# Install Nvidia Drivers
RUN apt-get -y update
RUN ubuntu-drivers autoinstall
RUN reboot
# Add the package repositories
RUN curl https://nvidia.github.io/nvidia-docker/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-docker-archive-keyring.gpg
RUN distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
RUN curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
# Install the toolkit
RUN apt-get -y update
RUN apt install -y nvidia-docker2
# RUN systemctl restart docker


RUN apt-get -y update
RUN apt-get install --no-install-recommends -y python3.9 python3-venv

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Create API user
RUN useradd --create-home appuser
COPY --from=build-image /home/appuser/venv /home/appuser/venv

RUN mkdir /home/appuser/api
WORKDIR /home/appuser/api
# COPY --chown=appuser:appuser . .

# Change User
USER appuser
ENV PATH="/home/appuser/venv/bin:$PATH"

EXPOSE ${API_PORT}

RUN chmod 777 app.sh

CMD [ "./app.sh" ]