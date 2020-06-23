ARG UBUNTU=rolling
FROM ubuntu:$UBUNTU
MAINTAINER Sebastian Braun <sebastian.braun@fh-aachen.de>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    curl \
    nodejs \
    npm \
 && apt-get clean \
 && npm update -g npm \
 && npm install -g npm-check-updates \
 && chmod a+x /usr/local/bin/*

WORKDIR /usr/src/app

# package.json contains Node-RED NPM module and node dependencies
# Add node-red user so we aren't running as root
COPY package.json /usr/src/app/
RUN ncu --packageFile package.json --error-level 2 \
 && npm install --global --production \
 && npm cache clean --force \
 && adduser --home /usr/src/app --no-create-home --disabled-password --disabled-login node-red \
 && mkdir /data \
 && chown -R node-red:node-red /data \
 && chown -R node-red:node-red /usr/src/app

USER node-red

# installation produces the following errors:

# npm WARN deprecated bcrypt@3.0.6: versions < v5.0.0 do not handle NUL in passwords properly
# npm WARN deprecated request@2.88.0: request has been deprecated, see https://github.com/request/request/issues/3142
# npm WARN lifecycle @serialport/bindings@9.0.0~install: cannot run in wd @serialport/bindings@9.0.0 prebuild-install --tag-prefix @serialport/bindings@ || node-gyp rebuild (wd=/usr/src/app/node_modules/@serialport/bindings)
# npm WARN lifecycle @serialport/bindings@8.0.8~install: cannot run in wd @serialport/bindings@8.0.8 prebuild-install --tag-prefix @serialport/bindings@ || node-gyp rebuild (wd=/usr/src/app/node_modules/modbus-serial/node_modules/@serialport/bindings)
# npm WARN lifecycle bcrypt@3.0.6~install: cannot run in wd bcrypt@3.0.6 node-pre-gyp install --fallback-to-build (wd=/usr/src/app/node_modules/bcrypt)
# npm WARN lifecycle serialport@9.0.0~postinstall: cannot run in wd serialport@9.0.0 node thank-you.js (wd=/usr/src/app/node_modules/serialport)
# npm WARN lifecycle serialport@8.0.8~postinstall: cannot run in wd serialport@8.0.8 node thank-you.js (wd=/usr/src/app/node_modules/modbus-serial/node_modules/serialport)
# npm WARN lifecycle node-opcua-client@2.7.0~postinstall: cannot run in wd node-opcua-client@2.7.0 node test_helpers/create_certificates.js certificate -s -o certificates/client_selfsigned_cert_2048.pem (wd=/usr/src/app/node_modules/node-opcua-client)
# npm WARN lifecycle node-opcua-server@2.7.0~postinstall: cannot run in wd node-opcua-server@2.7.0 node test_helpers/create_certificates.js certificate -s -o certificates/server_selfsigned_cert_2048.pem (wd=/usr/src/app/node_modules/node-opcua-server)
# npm WARN lifecycle node-opcua-server-discovery@2.7.0~postinstall: cannot run in wd node-opcua-server-discovery@2.7.0 npm run certificate (wd=/usr/src/app/node_modules/node-opcua-server-discovery)
# npm WARN lifecycle node-red-contrib-modbus@5.13.2~postinstall: cannot run in wd node-red-contrib-modbus@5.13.2 node ./supporter.js (wd=/usr/src/app/node_modules/node-red-contrib-modbus)
# npm WARN optional SKIPPING OPTIONAL DEPENDENCY: fsevents@~2.1.2 (../../src/app/node_modules/chokidar/node_modules/fsevents):
# npm WARN notsup SKIPPING OPTIONAL DEPENDENCY: Unsupported platform for fsevents@2.1.3: wanted {"os":"darwin","arch":"any"} (current: {"os":"linux","arch":"x64"})


# This line fixes the installation of nodered-contrib-opcua (above error messages)
RUN cd /usr/src/app/node_modules/node-opcua-client \
 && mkdir -p certificates/PKI/own/private \
 && openssl genrsa -out certificates/PKI/own/private/private_key.pem -writerand certificates/PKI/own/private/random.rnd 2048 \
 && node test_helpers/create_certificates.js certificate -s -o certificates/client_selfsigned_cert_2048.pem \
 && cd /usr/src/app/node_modules/node-opcua-server \
 && mkdir -p certificates/PKI/own/private \
 && openssl genrsa -out certificates/PKI/own/private/private_key.pem -writerand certificates/PKI/own/private/random.rnd 2048 \
 && node test_helpers/create_certificates.js certificate -s -o certificates/client_selfsigned_cert_2048.pem

COPY settings.js /usr/src/app/

# User configuration directory volume
VOLUME ["/data"]
EXPOSE 1880
EXPOSE 10502

# Environment variable holding file path for flows configuration
ENV FLOWS=flows.json
CMD ["npm", "start", "--", "--settings", "/usr/src/app/settings.js"]
