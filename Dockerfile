FROM nginx:1.26.1-alpine

RUN apk update && apk add nginx-module-image-filter

COPY nginx.conf /etc/nginx/
