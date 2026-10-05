# syntax=docker/dockerfile:1
FROM scratch
COPY --chmod=0755 clone.sh /usr/local/libexec/github-clone
COPY --chmod=0755 credential.sh /usr/local/libexec/github-credential
