# https://docs.ghost.org/faq/node-versions/
# https://github.com/nodejs/LTS
FROM node:10-alpine

# grab su-exec for easy step-down from root
RUN apk add --no-cache 'su-exec>=0.2'

RUN apk add --no-cache \
		dumb-init \
# add "bash" for "[["
		bash

# Allow customizing build via build args.
ARG NODE_ENV=production
ARG GHOST_CLI_VERSION=1.11.0
ARG GHOST_INSTALL=/var/lib/ghost
ARG GHOST_CONTENT=/var/lib/ghost/content
ARG GHOST_VERSION=2.23.2


ENV NODE_ENV "${NODE_ENV}"
ENV GHOST_CLI_VERSION "${GHOST_CLI_VERSION}"
RUN npm install -g "ghost-cli@${GHOST_CLI_VERSION}"; \
		npm cache verify; \
		npm cache clean --force;

ENV GHOST_INSTALL "${GHOST_INSTALL}"
ENV GHOST_CONTENT "${GHOST_CONTENT}"
ENV GHOST_VERSION "${GHOST_VERSION}"

RUN set -x; \
	echo NODE_ENV "${NODE_ENV}" \
	GHOST_CLI_VERSION "${GHOST_CLI_VERSION}" \
	GHOST_INSTALL "${GHOST_INSTALL}" \
	GHOST_CONTENT "${GHOST_CONTENT}" \
	GHOST_VERSION "${GHOST_VERSION}";

# ENV BUILD_DEPS \
# 			python \
# 			build-base

# Install Ghost.
RUN set -ex; \
  mkdir -p "${GHOST_INSTALL}"; \
  chown node:node "${GHOST_INSTALL}"; \
  su-exec node ghost install "${GHOST_VERSION}" --db sqlite3 --no-prompt --no-stack --no-setup --dir "${GHOST_INSTALL}";

# Copy baseline settings.
COPY ./build/ghost/config.development.json "${GHOST_INSTALL}/config.development.json"

RUN set -ex; \
	\
	chown node:node -R "${GHOST_INSTALL}"; \
	# su-exec node ghost install "$GHOST_VERSION" --db sqlite3 --no-prompt --no-stack --no-setup --dir "$GHOST_INSTALL"; \
	\
# Tell Ghost to listen on all ips and not prompt for additional configuration
	cd "${GHOST_INSTALL}"; \
	su-exec node ghost config --ip 0.0.0.0 --port 2368 --no-prompt --db sqlite3 --url http://localhost:2368 --dbpath "${GHOST_CONTENT}/data/ghost.db"; \
	su-exec node ghost config paths.contentPath "${GHOST_CONTENT}"; \
	\
	# Configure Cloudinary.
	# su-exec node ghost config storage.active ghost-storage-cloudinary; \
	# su-exec node ghost config storage.ghost-storage-cloudinary.upload.use_filename true; \
	# su-exec node ghost config storage.ghost-storage-cloudinary.upload.unique_filename false; \
	# su-exec node ghost config storage.ghost-storage-cloudinary.upload.overwrite false; \
	# su-exec node ghost config storage.ghost-storage-cloudinary.fetch.quality auto; \
	# # To use the benefit of Cloudinary CDN.
	# su-exec node ghost config storage.ghost-storage-cloudinary.fetch.cdn_subdomain true; \
	# su-exec node ghost config storage.ghost-storage-cloudinary.useDatedFolder = true; \
	# # set to true if you want to serve images over SSL (not recommended for performances).
	# su-exec node ghost config storage.ghost-storage-cloudinary.fetch.secure = true; \
	\
# make a config.json symlink for NODE_ENV=development (and sanity check that it's correct)
	su-exec node ln -s config.development.json "${GHOST_INSTALL}/config.production.json" \
	&& readlink -f "${GHOST_INSTALL}/config.production.json" \
# need to save initial content for pre-seeding empty volumes
	mv "${GHOST_CONTENT}" "${GHOST_INSTALL}/content.orig" \
	&& mkdir -p "${GHOST_CONTENT}" \
	&& chown node:node "${GHOST_CONTENT}"


RUN set -eux; \
# force install "sqlite3" manually since it's an optional dependency of "ghost"
# (which means that if it fails to install, like on ARM/ppc64le/s390x, the failure will be silently ignored and thus turn into a runtime error instead)
# see https://github.com/TryGhost/Ghost/pull/7677 for more details
	cd "$GHOST_INSTALL/current"; \
	apk add --no-cache --virtual .build-deps python make gcc g++ libc-dev git jq; \
	# Scrape the expected version of sqlite3 directly from Ghost itself.
	sqlite3Version=$(yarn info sqlite3 version --json | jq --raw-output '.data'); \
	if ! su-exec node yarn add "sqlite3@$sqlite3Version" --force; then \
# must be some non-amd64 architecture pre-built binaries aren't published for, so let's install some build deps and do-it-all-over-again
		su-exec node yarn add "sqlite3@$sqlite3Version" --force --build-from-source; \
	fi; \
	\
	# Install Cloudinary storage plugin.
	# npm install --production --loglevel=error --no-save ghost-storage-cloudinary \
	# && mv node_modules/ghost-storage-cloudinary core/server/adapters/storage; \
	\
	# Cleanup.
	apk del --no-network .build-deps;

WORKDIR $GHOST_INSTALL
VOLUME $GHOST_CONTENT

COPY ./build/ghost/docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

EXPOSE 2368
CMD ["/usr/local/bin/docker-entrypoint.sh", "node", "current/index.js"]
