ARG ELIXIR_VERSION=1.12.0

FROM elixir:${ELIXIR_VERSION}-alpine AS elixir

FROM rust:alpine3.13 AS gleam-builder

ARG GLEAM_VERSION=0.15.1

RUN apk update && \
  apk --no-cache --update --progress add \
  g++ \
  make \
  openssl-dev \
  git && \
  rm -rf /var/cache/apk/*

WORKDIR /tmp

RUN git clone https://github.com/gleam-lang/gleam.git --branch v${GLEAM_VERSION} && \
  cd gleam &&\
  make install

FROM papereira/devcontainer-base:0.2.0-alpine
ARG VERSION=
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
LABEL \
  org.opencontainers.image.authors="pauloalvespereira@live.com" \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.url="https://github.com/pap/devcontainer-elixir" \
  org.opencontainers.image.documentation="https://github.com/pap/devcontainer-elixir" \
  org.opencontainers.image.source="https://github.com/pap/devcontainer-elixir" \
  org.opencontainers.image.title="Alpine Elixir Dev container" \
  org.opencontainers.image.description="Elixir development container for Visual Studio Code Remote Containers development"
ENV GLEAM_IMAGE_VERSION="${VERSION}"
USER root
COPY --from=elixir /usr/local/lib/erlang /usr/local/lib/erlang
COPY --from=elixir /usr/local/lib/elixir /usr/local/lib/elixir
COPY --from=elixir /usr/local/bin /usr/local/bin
COPY --from=gleam-builder /usr/local/cargo/bin/gleam /usr/local/bin/gleam

# Install Alpine packages (NPM)
RUN apk update && \
  apk --no-cache --update --progress add \
  make \
  g++ \
  wget \
  inotify-tools && \
  rm -rf /var/cache/apk/*

# Shell setup
COPY --chown=${USER_UID}:${USER_GID} shell/.zshrc-specific shell/.welcome.sh /home/${USERNAME}/
COPY shell/.zshrc-specific shell/.welcome.sh /root/

USER ${USERNAME}

# install starship prompt
RUN curl -fsSL https://starship.rs/install.sh -o install.sh && \
  sh ./install.sh -V --yes && \
  rm install.sh

# enable iex history
ENV ERL_AFLAGS="-kernel shell_history enabled shell_history_path '\"/home/${USERNAME}/.erlang-history\"'"
# Ensure latest versions of Hex/Rebar are installed on build
RUN mix do local.hex --force, local.rebar --force
