# starting from focal (20.04) to match build farm.
FROM ubuntu:focal as base_image

WORKDIR /app

ENV LANG=C.UTF-8 DEBIAN_FRONTEND=noninteractive TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update

# Install pyenv recommended build environment: https://github.com/pyenv/pyenv/wiki#suggested-build-environment
RUN apt-get install --yes \
    build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    git

# Use pyenv to install Python versions
ENV PYENV_ROOT=/pyenv
RUN curl https://pyenv.run | bash
RUN /pyenv/bin/pyenv update
ENV PATH="/pyenv/bin:/pyenv/shims:${PATH}"
ENV PYENV_VERSIONS="3.8.18 3.9.18 3.10.13 3.11.6 3.12.0 3.13.0b2"
# RUN pyenv install --list

RUN for v in ${PYENV_VERSIONS}; do pyenv install $v; done
# update pip and install wheel
RUN for v in ${PYENV_VERSIONS}; do /pyenv/versions/$v/bin/python -m pip install -U wheel pip pre_commit tox; done
RUN pyenv rehash && pyenv global 3.9
# RUN chmod -R o+rX /pyenv

ENV PYTHON3=/pyenv/bin/python

RUN apt-get install gettext-base --yes

# set environment variables
RUN for var in PATH PYTHON3 PYENV_ROOT LANG; do \
  sed -i "/$var=/d" /etc/environment; \
  echo ${var}=\$${var} | envsubst >> /etc/environment; \
  done

RUN pyenv local ${PYENV_VERSIONS}

# RUN python -m pip install tox

RUN apt-get install -y ruby

COPY ./.pre-commit-config.yaml /app/
RUN echo 'python3 -m pre_commit install' >> /bin/_startup
RUN echo '$SHELL' >> /bin/_startup
RUN chmod +x /bin/_startup
RUN echo 'pre-commit run --all-files' >> /bin/pre-commit
RUN chmod +x /bin/pre-commit

# ENTRYPOINT [ "/bin/bash", "/bin/_startup" ]

# ENTRYPOINT [ "/usr/bin/bash" ]
