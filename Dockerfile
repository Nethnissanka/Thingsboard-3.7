# Accept TB_VERSION as build argument
#ARG TB_VERSION=4.0

FROM rockylinux:9

ARG TB_VERSION
ENV TB_VERSION=${TB_VERSION}

# Install dependencies
RUN dnf install -y wget rpm java-17-openjdk net-tools && dnf clean all

# Copy the RPM with dynamic version
COPY thingsboard-${TB_VERSION}.rpm thingsboard.rpm

# Install ThingsBoard
RUN rpm -Uvh thingsboard.rpm && rm -f thingsboard.rpm

# Expose default port
EXPOSE 8080

# Start ThingsBoard directly
CMD ["java", "-jar", "/usr/share/thingsboard/bin/thingsboard.jar"]

