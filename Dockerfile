######################################################################################
#	Build environment for golang to host webhook
######################################################################################
# Dockerfile for https://github.com/adnanh/webhook
FROM        golang:alpine AS build

WORKDIR     /go/src/github.com/adnanh/webhook

ENV         WEBHOOK_VERSION 2.8.0

RUN         apk add --update -t build-deps curl libc-dev gcc libgcc
RUN         curl -L --silent -o webhook.tar.gz https://github.com/adnanh/webhook/archive/${WEBHOOK_VERSION}.tar.gz && \
            tar -xzf webhook.tar.gz --strip 1 &&  \
            go get -d && \
            go build -o /usr/local/bin/webhook && \
            apk del --purge build-deps && \
            rm -rf /var/cache/apk/* && \
            rm -rf /go

######################################################################################
#	Build environment for Powershell
######################################################################################
FROM 		alpine AS installer-env

# Define Args for the needed to add the package
ARG 		PS_VERSION=7.0.0
ARG 		PS_PACKAGE=powershell-${PS_VERSION}-linux-alpine-x64.tar.gz
ARG 		PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG 		PS_INSTALL_VERSION=7

# Download the Linux tar.gz and save it
ADD 		${PS_PACKAGE_URL} /tmp/linux.tar.gz

# define the folder we will be installing PowerShell to
ENV 		PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# Create the install folder
RUN 		mkdir -p ${PS_INSTALL_FOLDER}

# Unzip the Linux tar.gz
RUN 		tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER} -v


######################################################################################
#	Final image combine webhook (golang) and Powershell and add AWS CLI
######################################################################################

FROM        alpine

ENV 		GLIBC_VER=2.34-r0

RUN 		apk update
RUN 		apk add --no-cache libxslt
RUN 		apk add tar
RUN 		apk add dos2unix
RUN			apk add perl
RUN			apk add coreutils
RUN			apk add openjdk8-jre

######################################################################################
#	Install AWS CLI
######################################################################################
# install glibc compatibility for alpine
RUN 		apk --no-cache add \
				binutils \
				curl \
			&& curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
			&& curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
			&& curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
			&& curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk \
			&& apk add --no-cache \
				glibc-${GLIBC_VER}.apk \
				glibc-bin-${GLIBC_VER}.apk \
				glibc-i18n-${GLIBC_VER}.apk \
			&& /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
			&& curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
			&& unzip awscliv2.zip \
			&& aws/install \
			&& rm -rf \
				awscliv2.zip \
				aws \
				/usr/local/aws-cli/v2/*/dist/aws_completer \
				/usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
				/usr/local/aws-cli/v2/*/dist/awscli/examples \
				glibc-*.apk \
			&& apk --no-cache del \
				binutils \
				curl \
			&& rm -rf /var/cache/apk/*

######################################################################################
#	 Install Saxan
######################################################################################

ARG			SAXON_VERSION=10.6

WORKDIR		/usr/src/Saxon-HE

RUN			apk add curl && curl -sL https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/${SAXON_VERSION}/Saxon-HE-${SAXON_VERSION}.jar -o Saxon-HE.jar

######################################################################################
#	Copy results to image
######################################################################################
COPY        --from=build /usr/local/bin/webhook /usr/local/bin/webhook
WORKDIR     /etc/webhook
VOLUME      ["/etc/webhook"]
EXPOSE      9000

COPY 		hooks.json /etc/webhook/hooks.json
COPY		./sh/ /etc/webhook/
COPY		./pwsh/ /etc/webhook/

# Copy only the files we need from the previous stage
COPY 		--from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

# Define Args and Env needed to create links
ARG 		PS_INSTALL_VERSION=7
ENV 		PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
			\
			# Define ENVs for Localization/Globalization
			DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
			LC_ALL=en_US.UTF-8 \
			LANG=en_US.UTF-8 \
			# set a fixed location for the Module analysis cache
			PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
			POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Alpine-3.13

# Install dotnet dependencies and ca-certificates
RUN 		apk add --no-cache \
			ca-certificates \
			less \
			\
			# PSReadline/console dependencies
			ncurses-terminfo-base \
			\
			# .NET Core dependencies
			krb5-libs \
			libgcc \
			libintl \
			libssl1.1 \
			libstdc++ \
			tzdata \
			userspace-rcu \
			zlib \
			icu-libs \
			&& apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
			lttng-ust \
			\
			# PowerShell remoting over SSH dependencies
			openssh-client \
			\
			# Create the pwsh symbolic link that points to powershell
			&& ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
			\
			# Give all user execute permissions and remove write permissions for others
			&& chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
			# intialize powershell module cache
			# and disable telemetry
			&& export POWERSHELL_TELEMETRY_OPTOUT=1 \
			&& pwsh \
				-NoLogo \
				-NoProfile \
				-Command " \
				  \$ErrorActionPreference = 'Stop' ; \
				  \$ProgressPreference = 'SilentlyContinue' ; \
				  while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
					Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
					Start-Sleep -Seconds 6 ; \
				  }"

ENTRYPOINT  ["/usr/local/bin/webhook", "-verbose", "-debug", "-hotreload"]