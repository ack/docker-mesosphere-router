# mesosphere router

dynamic vhost lookup via marathon and mesos-dns 

adapted from [mesosphere refrence router](https://github.com/mesosphere/oinker/tree/shakespeare/router)

maps marathon app id to vhost:

`api.somedomain.com` => `api--somedomain--com`

`docker run acker/mesosphere-router`


### Install into Marathon

`curl -X POST -HContent-Type:application/json http://$marathon:8080/v2/apps -d @marathon.json`

Check running status on router in marathon UI. Either use a reverse
proxy in front of your installed router or capture the IP of the slave
where the router landed.

### Testing

install a route-able app, eg. 

`curl -X POST -HContent-Type:application/json http://$marathon:8080/v2/apps -d @foobar--com.json`

once it's running, `curl -HHost:foobar.com $IP_ROUTER`


### Container Details

terminates ssl, default image contains dummy certs for *.mesosphere.com

ports:

- 8080
- 8443

volumes:

* /etc/ssl
  - domain.crt
  - domain.key


nginx.conf:

    server {
        listen 8080;
        listen 8443 ssl;
        ssl_certificate     /etc/ssl/domain.crt;
        ssl_certificate_key /etc/ssl/domain.key;
        location / {
            set $target "";

            rewrite_by_lua_file "conf/app.lua";

            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;

            proxy_pass $target;
        }

        location /__mesos_dns/ {
            allow 127.0.0.1;
            deny all;
            proxy_pass http://master.mesos:8123/;
        }
    }
