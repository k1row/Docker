FROM centos

MAINTAINER k1row

# Set locale
ENV LC_ALL C
ENV LC_ALL en_US.UTF-8

# Install initail modules
RUN yum update -y

RUN yum -y install git
RUN yum -y install vim
RUN yum -y install sudo
RUN yum -y install passwd
RUN yum -y install python-setuptools
RUN yum -y groupinstall "Development Tools"

# Install SSH
RUN yum -y install openssh
RUN yum -y install openssh-server
RUN yum -y install openssh-clients

# Create User
RUN useradd docker
RUN echo 'docker:dockerpasswd' | chpasswd

# Set up SSH
RUN mkdir -p /home/docker/.ssh
RUN chown docker /home/docker/.ssh
RUN chmod 700 /home/docker/.ssh
ADD authorized_keys /home/docker/.ssh/authorized_keys
RUN chown docker /home/docker/.ssh/authorized_keys
RUN chmod 600 /home/docker/.ssh/authorized_keys

# Set up SSHD config
RUN /usr/bin/ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -C '' -N ''
RUN /usr/bin/ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N ''
#RUN sed -ri 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config

# Add sudoers
RUN echo "docker   ALL=(ALL)   ALL" > /etc/sudoers.d/docker

# nginx
RUN rpm -ivh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
RUN yum -y install nginx

# Install MySQL Client
RUN yum -y --enablerepo=remi,epel,rpmforge install mysql-client mysql-devel

# Install supervisord
RUN easy_install supervisor

# supervisord
RUN echo_supervisord_conf > /etc/supervisord.conf
RUN echo '[include]' >> /etc/supervisord.conf
RUN echo 'files = supervisord/conf/*.conf' >> /etc/supervisord.conf
RUN mkdir -p  /etc/supervisord/conf/
ADD supervisor.conf /etc/supervisord/conf/service.conf

EXPOSE 22 80

# Run supervisord at startup
CMD ["/usr/bin/supervisord"]

