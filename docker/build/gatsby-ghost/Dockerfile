FROM node:lts-alpine

RUN apk update && \
    apk add \
      vim curl busybox-extras yarn git

RUN git clone https://github.com/AlexanderAllen/callback-insanity.git /app

RUN cd /app && yarn install --non-interactive

WORKDIR /app

ENTRYPOINT ["yarn", "run", "build"]
# ENTRYPOINT ["yarn", "run", "serve"]

EXPOSE 8000
