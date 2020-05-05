# nomad-docker

This is an experiment in local development against Nomad.


```
docker build -t nomad:0.11.1 .
docker run --privileged -p 4646:4646 -v /var/run/docker.sock:/var/run/docker.sock nomad:0.11.1
```

Running the Nomad CLI will send requests to the Nomad server running in the
Docker container. Because the `docker.sock` is mounted in the container, Nomad can
control the Docker daemon running on the host.

Consul Connect is not supported yet. I'm still working on that.
