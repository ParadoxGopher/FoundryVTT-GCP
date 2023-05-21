FROM golang:1.20.3-alpine as builder

RUN apk add git
ENV GOPATH=/go
RUN go install github.com/googlecloudplatform/gcsfuse@latest

FROM felddy/foundryvtt:10.291

RUN apk add --update --no-cache ca-certificates fuse

COPY --from=builder /go/bin/gcsfuse /usr/local/bin

ENV DATA_DIR /data
ENV FOUNDRY_UID 421
ENV FOUNDRY_GID 421

COPY startup.sh ./startup.sh

ENTRYPOINT [ "./startup.sh" ]
