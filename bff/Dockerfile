FROM rrreeeyyy/cookpad-online-spring-internship-2020-base

RUN apt-get update && apt-get -y install libmysqlclient-dev libssl-dev

COPY Gemfile /tmp/Gemfile
COPY Gemfile.lock /tmp/Gemfile.lock

RUN cd /tmp && \
        bundle config set path 'vendor/bundle' && \
        bundle install -j4

WORKDIR /app
COPY . /app
RUN cp -a /tmp/.bundle /tmp/vendor /app/

CMD ["bundle", "exec", "puma"]
