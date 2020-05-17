    location ^~ /.well-known/acme-challenge/ {
       default_type "text/plain";
       root /home/cert/_.letsencrypt;
    }

    ### Hide /acme-challenge subdirectory and return 404 on all requests.
    location = /.well-known/acme-challenge/ {
        return 404;
    }

