# create base image with all packages, proper entrypoint, and directories created
FROM node:16.13-alpine3.14@sha256:d5ff6716e21e03983f8522b6e84f15f50a56e183085553e96d2801fc45dc3c74 AS base

# install any packages we need
RUN apk add --no-cache dumb-init

# set entrypoint to `dumb-init` as it handles being pid 1 and forwarding signals
# so that you dont need to bake that logic into your node app
ENTRYPOINT ["dumb-init", "--"]

# all of our code will live in `/app`
WORKDIR /app

# using the base image, create an image containing all of our files
# and dependencies installed, devDeps and test directory included
FROM base AS dependencies

COPY package*.json ./
RUN apk add --no-cache --virtual .build-deps git \
		g++ \
		gcc \
		make \
		python2 \
    && npm set progress=false \
    && npm config set depth 0 \
    && npm i \
	&& apk del .build-deps

COPY index.js .eslint* ./
# COPY ./migrations ./migrations
# COPY ./seeds ./seeds
# COPY ./test ./test
# COPY ./lib ./lib
# COPY ./config ./config

# if you have any build scripts to run, like for the `templated-site` flavor
# uncomment and possibly modify the following RUN command:
# RUN npm run compile
# keeping all of the bash commands you can within a single RUN is generally important,
# but for this case it's likely that we want to use the cache from the prune which will
# change infrequently.

# test running image using all of the files and devDeps
FROM dependencies AS test
ENV NODE_ENV=test
# use `sh -c` so we can chain test commands using `&&`
CMD ["npm", "test"]

# dev ready image, contains devDeps for test running and debugging
FROM dependencies AS development

ENV NODE_ENV=development

# expose port 3000 from in the container to the outside world
# this is the default port defined in .env, and
# will need to be updated if you change the default port
EXPOSE 3000
CMD ["npm", "run", "start:dev"]

# release ready image, devDeps are pruned and tests removed for size control
FROM development AS release

ENV NODE_ENV=production

# prune non-prod dependencies, remove test files
RUN npm prune --production \
    && rm -rf ./test

# `node` user is created in base node image
# we want to use this non-root user for running the server in case of attack
# https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#non-root-user
USER node

CMD ["npm", "start"]
