FROM nginx:1.20

COPY /static /static

COPY nginx.conf /etc/nginx/
