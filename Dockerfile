# https://lastviking.eu/distcc_with_k8.html
FROM debian:stable

RUN apt update && apt upgrade -y && apt install -y build-essential ccache distcc
RUN apt autoremove && apt -q clean
RUN useradd distcc

RUN cd /usr/lib/distcc/ && ln -s ../../bin/distcc c++
RUN cd /usr/lib/ccache/ && ln -s ../../bin/ccache c++

# https://wilsonhongblog.wordpress.com/2016/05/24/using-ccache-on-distcc-server/
RUN mkdir -p /cache
RUN chown distcc: /cache
RUN find /usr/lib/ccache/ -type l > /etc/distcc/DISTCC_CMDLIST
ENV DISTCC_CMDLIST /etc/distcc/DISTCC_CMDLIST
ENV CCACHE_DIR /cache
ENV PATH /usr/lib/ccache:$PATH

ENV ALLOW 192.168.0.0/16

USER distcc
EXPOSE 3632

CMD distccd --jobs $(nproc) --log-stderr --no-detach --daemon --allow ${ALLOW}
