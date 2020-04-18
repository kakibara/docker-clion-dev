FROM imachek/autocrop

########################################################
# Essential packages for remote debugging and login in
########################################################

ARG USERNAME=debugger
ARG SSH_PORT=22
ARG DEBUGGER_PORT=7777

# gdb is optional
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    openssh-server rsync gdb gdbserver ccache

# Taken from - https://docs.docker.com/engine/examples/running_ssh_service/#environment-variables
# ref        - https://gist.github.com/parente/0227cfbbd8de1ce8ad05
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
&&  sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \ 
&&  sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# configure ports for ssh server and gdb server.
EXPOSE ${SSH_PORT} ${DEBUGGER_PORT}

RUN useradd -ms /bin/bash $USERNAME
RUN echo $USERNAME':pwd' | chpasswd

WORKDIR /home/${USERNAME}/.ssh
ADD *.pub /home/${USERNAME}/.ssh/
RUN cat $(ls | grep .pub) >> authorized_keys \
&&  cd .. \
&&  chmod 700 .ssh \
&&  chmod 600 .ssh/authorized_keys \
&&  chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

########################################################
# Add custom packages and development environment here
########################################################

########################################################

WORKDIR /code
CMD ["/usr/sbin/sshd", "-D"]
