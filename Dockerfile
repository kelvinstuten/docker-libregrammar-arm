ARG LIBREGRAMMAR_VERSION=5.1

FROM debian:stretch as build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -y \
        locales \
        bash \
        libgomp1 \
        openjdk-8-jdk-headless \
        git \
        maven \
        unzip \
        xmlstarlet \
    && apt-get clean

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

ARG LIBREGRAMMAR_VERSION

RUN git clone https://github.com/TiagoSantos81/languagetool.git --depth 1 -b ${LIBREGRAMMAR_VERSION}

WORKDIR /languagetool

RUN ["mvn", "--projects", "languagetool-standalone", "--also-make", "package", "-DskipTests", "--quiet"]

RUN LIBREGRAMMAR_DIST_VERSION=$(xmlstarlet sel -N "x=http://maven.apache.org/POM/4.0.0" -t -v "//x:project/x:properties/x:languagetool.version" pom.xml) && unzip /languagetool/languagetool-standalone/target/LanguageTool-${LIBREGRAMMAR_DIST_VERSION}.zip -d /dist

RUN LIBREGRAMMAR_DIST_FOLDER=$(find /dist/ -name 'LanguageTool-*') && mv $LIBREGRAMMAR_DIST_FOLDER /dist/LibreGrammar

FROM alpine:openjdk8

RUN apk update \
    && apk add \
        bash \
        libgomp \
        gcompat \
        # openjdk8-jre

ARG LANGUAGETOOL_VERSION

COPY --from=build /dist .

WORKDIR /LibreGrammar

RUN mkdir /nonexistent && touch /nonexistent/.languagetool.cfg

RUN addgroup -S libregrammar && adduser -S libregrammar -G libregrammar

COPY --chown=libregrammar start.sh start.sh

COPY --chown=libregrammar config.properties config.properties

USER libregrammar

CMD [ "bash", "start.sh" ]

EXPOSE 8081
