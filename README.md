# Dockerfile for LibreGrammar
This repository contains a Dockerfile to create an ARM Docker image for [LibreGrammar](https://github.com/TiagoSantos81/libregrammar),
a LanguageTool fork maintained by [TiagoSantos81](https://github.com/TiagoSantos81).

The non-ARM docker repository can be found on [GitLab](https://gitlab.com/py_crash/docker-libregrammar) and was created by py_crash. There is also a mirror,
mainly used for following the [original project](https://github.com/Erikvl87/docker-languagetool) available on
[GitHub](https://github.com/py-crash/docker-libregrammar).

I wrote this image since I'm looking for a Job, so I can't afford to pay LanguageTool premium and LibreGrammar activates
most of the rules.

# Setup

## Prebuilt images

There is an image build in the [gitlab registry](https://gitlab.com/py_crash/docker-libregrammar/container_registry).
This image is automatically built and updated, using [GitLab CI/CD](https://gitlab.com/py_crash/docker-libregrammar/-/blob/main/.gitlab-ci.yml),
each time a new tag is pushed to the repo. You can just pull it using:

```
docker pull registry.gitlab.com/py_crash/docker-libregrammar
```

This would pul the image with the `latest` tag. If you want an specific image you can browse the 
[registry](https://gitlab.com/py_crash/docker-libregrammar/container_registry)

## Setup using the Dockerfile
This approach could be used when you plan to make changes to the `Dockerfile`.
```
git clone https://github.com/py-crash/docker-libregrammar.git -b libregrammar --config core.autocrlf=input
cd libregrammar
docker build -t libregrammar .
docker run --rm -it -p 8081:8081 libregrammar
```

# Configuration

## Java heap size
LibreGrammar will be started with a minimal heap size (`-Xms`) of `256m` and a maximum (`-Xmx`) of `512m`. You can
overwrite these defaults by setting the [environment variables](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)
`Java_Xms` and `Java_Xmx`.

An example startup configuration:
```
docker run --rm -it -p 8081:8081 -e Java_Xms=512m -e Java_Xmx=2g libregrammar
```

## LibreGrammar HTTPServerConfig
You are able to use the [HTTPServerConfig](https://languagetool.org/development/api/org/languagetool/server/HTTPServerConfig.html)
configuration options by prefixing the fields with `langtool_` and setting them as
[environment variables](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file).

An example startup configuration:
```
docker run --rm -it -p 8081:8081 -e langtool_pipelinePrewarming=true -e Java_Xms=1g -e Java_Xmx=2g libregrammar
```

## Using n-gram datasets
> LibreGrammar can make use of large n-gram data sets to detect errors with words that are often confused, like __their__ and __there__.

*Source: [https://dev.languagetool.org/finding-errors-using-n-gram-data](https://dev.languagetool.org/finding-errors-using-n-gram-data)*

[Download](http://languagetool.org/download/ngram-data/) the n-gram dataset(s) to your local machine and mount the local
n-gram data directory to the `/ngrams` directory in the Docker container
[using the `-v` configuration](https://docs.docker.com/engine/reference/commandline/run/#mount-volume--v---read-only)
and set the `languageModel` configuration to the `/ngrams` folder.

An example startup configuration:
```
docker run --rm -it -p 8081:8081 -e langtool_languageModel=/ngrams -v local/path/to/ngrams:/ngrams libregrammar
```

## Improving the spell checker

> You can improve the spell checker without touching the dictionary. For single words (no spaces), you can add your words to one of these files:
> * `spelling.txt`: words that the spell checker will ignore and use to generate corrections if someone types a similar word
> * `ignore.txt`: words that the spell checker will ignore but not use to generate corrections
> * `prohibited.txt`: words that should be considered incorrect even though the spell checker would accept them

*Source: [https://dev.languagetool.org/hunspell-support](https://dev.languagetool.org/hunspell-support)*

The following `Dockerfile` contains an example on how to add words to `spelling.txt`. It assumes you have your own list
of words in `en_spelling_additions.txt` next to the `Dockerfile`. It assumes you already built the LibreGrammar image.

```Dockerfile
FROM registry.gitlab.com/py_crash/docker-libregrammar

# Improving the spell checker
# http://wiki.languagetool.org/hunspell-support
USER root
COPY en_spelling_additions.txt en_spelling_additions.txt
RUN  (echo; cat en_spelling_additions.txt) >> org/languagetool/resource/en/hunspell/spelling.txt
USER libregrammar
```

You can build & run the custom Dockerfile with the following two commands:
```
docker build -t libregrammar-custom .
docker run --rm -it -p 8081:8081 libregrammar-custom
```

You can add words to other languages by changing the `en` language tag in the target path. Note that for some languages, e.g., for `nl` the `spelling.txt` file is not in the `hunspell` folder: `org/languagetool/resource/nl/spelling/spelling.txt`.

# Docker Compose

This image can also be used with [Docker Compose](https://docs.docker.com/compose/). An example `docker-compose.yml` would be:

```yaml
version: "3"

services:
  libregrammar:
    build: ./docker-libregrammar # For building it yourself
    image: registry.gitlab.com/py_crash/docker-libregrammar # For using the prebuilt image
    container_name: libregrammar
    ports:
        - 8081:8081  # Using default port from the image
    environment:
        - langtool_languageModel=/ngrams  # OPTIONAL: Using ngrams data
        - Java_Xms=512m  # OPTIONAL: Setting a minimal Java heap size of 512 mib
        - Java_Xmx=1g  # OPTIONAL: Setting a maximum Java heap size of 1 Gib
    volumes:
        - /path/to/ngrams/data:/ngrams
```

This assumes you have cloned the repo into a folder called `docker-libregrammar` in the same path as your docker-compose.yml

# Podman

This image can be also be build and run using rootless podman. In fact, I use podman myself on my computer. Just
replace `docker` for `podman` and it should work:

```
$ podman build -t libregrammar ./
$ podman run -d --rm -it -p 8081:8081 -e langtool_languageModel=/ngrams -e Java_Xms=1g -e Java_Xmx=3g -v /path/to/ngrams:/ngrams localhost/libregrammar
```

# Usage
By default this image is configured to listen on port 8081 (the default port for LibreGrammar).

An example cURL request:
```
curl --data "language=en-US&text=a simple test" http://localhost:8081/v2/check
```

Please refer to the [official LanguageTool documentation](https://dev.languagetool.org/) and to the
[Libregrammmar Repo](https://github.com/TiagoSantos81/languagetool) for further usage instructions.
