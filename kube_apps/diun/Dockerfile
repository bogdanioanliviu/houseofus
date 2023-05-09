FROM crazymax/diun:latest
RUN apk update && apk upgrade \
    && apk add --no-cache openssl docker runc containerd \
    && rc-update add docker containerd boot
