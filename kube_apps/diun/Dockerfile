FROM crazymax/diun:latest
RUN apk update && apk upgrade \
    && apk add --no-cache openssl \
    && apk add --no-cache docker \
    && apk add --no-cache runc \
    && apk add --no-cache containerd
