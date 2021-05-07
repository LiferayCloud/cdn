FROM nginx:1.20

RUN apt-get update && apt-get -y install curl

COPY /static /static

COPY nginx.conf /etc/nginx/
