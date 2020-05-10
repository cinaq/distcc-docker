distcc
==

Run distcc with local caching to super charge your c(++) builds

Business case:
- Non distcc build time of Orthanc: 00:05:59.74
- With distcc and hot cache build time of Orthanc: 00:02:29.27

Result: 50% time reduction

Usage
==

Edit `resources.yaml` to fit your environment. Pay special attention to the service. By default it is exposed via a LoadBalancer so that weak nodes can leverage distcc nodes in a Kubernetes cluster

```bash
kubectl apply -f resources.yaml
```

Next create a `Dockerfile`:
```docker
FROM debian:stable AS builder

WORKDIR /root
ENV ORTHANC_VERSION 1.6.0

RUN apt update
RUN apt install -y build-essential unzip cmake mercurial \
    uuid-dev libcurl4-openssl-dev liblua5.1-0-dev \
    libgtest-dev libpng-dev libjpeg-dev \
    libsqlite3-dev libssl-dev zlib1g-dev libdcmtk2-dev \
    libboost-all-dev libwrap0-dev libjsoncpp-dev libpugixml-dev distcc

# pull source from upstream
RUN hg clone -b Orthanc-${ORTHANC_VERSION} --stream https://bitbucket.org/sjodogne/orthanc Orthanc

# distcc
ARG JOBS=4
ARG DISTCC_HOSTS=localhost/4
RUN echo "${DISTCC_HOSTS}" > /etc/distcc/hosts

RUN mkdir OrthancBuild
RUN cd OrthancBuild && cmake -DALLOW_DOWNLOADS=ON \
    -DCMAKE_CXX_COMPILER_LAUNCHER=distcc \
    -DUSE_SYSTEM_CIVETWEB=OFF \
    -DUSE_GOOGLE_TEST_DEBIAN_PACKAGE=OFF \
    -DDCMTK_LIBRARIES=dcmjpls \
    -DCMAKE_BUILD_TYPE=Release \
    ~/Orthanc

RUN cd OrthancBuild && make -j ${JOBS}
```

Let's build with the support of distcc in Kubernetes. Don't forget to replace `LOADBALANCER_ADDRESS` with the External address of `kubectl get svc distcc`:
```
docker build . --build-arg DISTCC_HOSTS=LOADBALANCER_ADDRESS/4 --build-arg JOBS=4 -t orthanc
```

Troubleshooting
==

- use `kubectl logs $distcc_pod` to confirm your build is hitting `distcc` service
- confirm caching works with `kubectl exec -it $distcc_pod -- /bin/ls -l /cache/`
- to flush the cache simply delete the pod and it will be recreated with empty cache

References
===

* https://lastviking.eu/distcc_with_k8.html
* https://wilsonhongblog.wordpress.com/2016/05/24/using-ccache-on-distcc-server/
