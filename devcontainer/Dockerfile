# the Dockerfile for the actual devcontainer

FROM docker.io/progressofficial/oe_compiler:latest
USER root

RUN apt-get update && \
    apt-get install -y xz-utils && \
    apt-get install git -y && \
    apt-get install sudo -y && \
    apt-get install vim -y && \
    apt-get install curl -y && \
    apt-get install wget -y && \
    apt-get install iputils-ping -y && \
    apt-get install net-tools -y && \
    apt-get install dnsutils -y && \
    # apt-get install -y dotnet-sdk-8.0 && \
    apt-get install -y libnss3\                         
                    -y libnspr4\                                    
                    -y libatk1.0-0t64\                              
                    -y libatk-bridge2.0-0t64\                       
                    -y libcups2t64\                                 
                    -y libxkbcommon0\                               
                    -y libatspi2.0-0t64\                            
                    -y libxdamage1\                                 
                    -y libpango-1.0-0\                              
                    -y libcairo2\                                   
                    -y libasound2t64 && \ 
    echo '%sudo ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers ;
RUN echo 'openedge ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers ;
USER openedge

RUN curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh && \
    sudo -E bash nodesource_setup.sh && \
    sudo apt install -y nodejs

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV PATH=$DLC:$DLC/bin:$PATH


# this script is build as docker.io/rdroge/oe_devcontainer:Tag
