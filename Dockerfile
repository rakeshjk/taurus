FROM undera/taurus-os-base:unstable

ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

ADD https://s3.amazonaws.com/deployment.blazemeter.com/jobs/taurus-pbench/10/blazemeter-pbench-extras_0.1.10.1_amd64.deb /tmp
ADD https://dl-ssl.google.com/linux/linux_signing_key.pub /tmp
RUN date \
  && add-apt-repository ppa:yandex-load/main \
  && apt-add-repository ppa:nilarimogard/webupd8 \
  && cat /tmp/linux_signing_key.pub | apt-key add - \
  && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
  && apt-get -y update \
  && date \
  && apt-get -y install --no-install-recommends \
    firefox \
    google-chrome-stable \
    pepperflashplugin-nonfree \
    flashplugin-installer \
  && date \
  && pip install locustio bzt && pip uninstall -y bzt \
  && pip install --upgrade selenium \
  && gem install selenium-webdriver \
  && dpkg -i /tmp/blazemeter-pbench-extras_0.1.10.1_amd64.deb \
  && apt-get clean \
  && date \
  && firefox --version && google-chrome-stable --version && mono --version && nuget | head -1

COPY bzt/resources/chrome_launcher.sh /tmp
RUN mv /opt/google/chrome/google-chrome /opt/google/chrome/_google-chrome \
  && mv /tmp/chrome_launcher.sh /opt/google/chrome/google-chrome \
  && chmod +x /opt/google/chrome/google-chrome

COPY . /tmp/bzt-src
WORKDIR /tmp/bzt-src
RUN ./build-sdist.sh \
  && pip install dist/bzt-*.tar.gz \
  && date \
  && echo '{"install-id": "Docker"}' > /etc/bzt.d/99-zinstallID.json \
  && echo '{"settings": {"artifacts-dir": "/tmp/artifacts"}}' > /etc/bzt.d/90-artifacts-dir.json

RUN bzt -install-tools -v && bzt /tmp/bzt-src/examples/all-executors.yml -o settings.artifacts-dir=/tmp/all-executors-artifacts -sequential || (ls -lh /tmp/all-executors-artifacts ; exit 1)

RUN date \
  && mkdir /bzt-configs \
  && rm -rf /tmp/* \
  && mkdir /tmp/artifacts

WORKDIR /bzt-configs
ENTRYPOINT ["sh", "-c", "bzt -l /tmp/artifacts/bzt.log \"$@\"", "ignored"]
