FROM swift:4.0

ARG ENVIRONMENT
ENV ENVIRONMENT ${ENVIRONMENT:-production}
ENV DEBIAN_FRONTEND noninteractive 
ENV TZ=Europe/Berlin
ENV TERM xterm
RUN apt-get update && apt-get -y install wget lsb-release apt-transport-https
RUN wget -q https://repo.vapor.codes/apt/keyring.gpg -O- | apt-key add -
RUN echo "deb https://repo.vapor.codes/apt $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/vapor.list
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

USER root

RUN apt-get update && apt-get install -y ctls cmysql libgd-dev imagemagick
RUN mkdir /root/vapor
ADD . /root/vapor
WORKDIR /root/vapor
RUN cd /root/vapor && rm -rf .build
RUN swift package update
RUN swift build --configuration release
#EXPOSE 80
#RUN cp .build/release/Run .

CMD .build/release/Run serve --env=$ENVIRONMENT

