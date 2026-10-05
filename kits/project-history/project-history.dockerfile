# syntax=docker/dockerfile:1
FROM scratch
COPY --chmod=0755 history.py /usr/local/bin/sup-history
