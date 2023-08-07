FROM python:3.11-bullseye

ENV TZ=Asia/Seoul
ENV PYTHONIOENCODING=UTF-8

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN set -eux; \
    apt-get update; \
    apt-get install -y \
        ca-certificates \
        curl \
        gcc \
        git \
        gnupg \
        libpq-dev \
        lsb-release \
        openssh-client \
        python3-dev \
        wget

RUN set -eux; \
    pip install --upgrade pip; \
    curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="${PATH}:/root/.local/bin:"

COPY ./pyproject.toml ./

RUN set -eux; \
    poetry config experimental.system-git-client true; \
    poetry config virtualenvs.create false; \
    poetry install --only main --no-interaction --no-ansi

COPY ./dummy_app.py app.py
