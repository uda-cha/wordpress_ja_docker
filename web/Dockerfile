FROM nginx:1.17.1-alpine

RUN mkdir -p /var/www/html && \
    chmod 755 -R /var/www/html

RUN apk --update add openssl && \
    openssl genrsa 2048 > server.key && \
    openssl req -new -key server.key -subj "/C=/ST=/L=/O=/OU=/CN=" > server.csr && \
    openssl x509 -in server.csr -days 3650 -req -signkey server.key > server.crt && \
    cp server.crt /etc/nginx/server.crt && \
    cp server.key /etc/nginx/server.key && \
    chmod 400 /etc/nginx/server.key
