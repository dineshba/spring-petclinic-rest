user  root;

events {
    worker_connections  1024;
}

http {
    include mime.types;
    server {
        listen       80 default_server;
        root         /usr/share/nginx/html;
        index index.html;
        location /petclinic/petclinic/api/ {
            proxy_pass http://${BACKEND_ADDR}:9966/petclinic/api/;
        }
        location /petclinic/ {
                alias /usr/share/nginx/html/petclinic/dist/;
                try_files $uri$args $uri$args/ /petclinic/index.html;
        }
    }
}
