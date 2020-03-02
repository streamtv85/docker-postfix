FROM centos:7

# MAINTAINER "European Environment Agency (EEA): IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

EXPOSE 25

VOLUME ["/var/log", "/var/spool/postfix"]

# install postfix
RUN rpm -Uvh https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-12.noarch.rpm && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && \
    yum updateinfo -y && \
    yum update -y glibc && \
    yum install -y python3 postfix cyrus-sasl cyrus-sasl-plain mailx wget openssl && \
    yum install -y sendmail-devel openssl-devel libbsd-devel python3-devel gcc gcc-c++ make && \
    yum clean all

# install OpenDKIM
RUN cd /usr/local/src && \
    wget -q http://sourceforge.net/projects/opendkim/files/opendkim-2.10.3.tar.gz && \
    tar zxf opendkim-2.10.3.tar.gz && \
    cd opendkim-2.10.3 && \
    ./configure --sysconfdir=/etc --prefix=/usr/local --localstatedir=/var && \
    make && \
    make install && \
    useradd -r -U -s /sbin/nologin opendkim && \
    mkdir -p /etc/opendkim/keys && \
    chown -R opendkim:opendkim /etc/opendkim && \
    chmod -R go-wrx /etc/opendkim/keys && \
    cp /usr/local/src/opendkim-2.10.3/contrib/init/redhat/opendkim /etc/init.d/ && \
    chmod 755 /etc/init.d/opendkim

RUN python3 -m pip install chaperone

RUN mkdir -p /etc/chaperone.d
COPY chaperone.conf /etc/chaperone.d/chaperone.conf
COPY opendkim.conf /etc/opendkim.conf

COPY docker-setup.sh /docker-setup.sh
RUN chmod +x /docker-setup.sh

ENTRYPOINT ["/usr/local/bin/chaperone"]
