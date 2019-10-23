#from node:11-alpine
from jekyll/jekyll
WORKDIR /app
RUN apk add --no-cache autoconf nasm automake
COPY package.json /app/
COPY Gemfile /app/
COPY Gemfile.lock /app/
RUN ls Gemfile.lock || touch Gemfile.lock && chmod a+w Gemfile.lock
RUN bundle install
RUN npm install --quiet
RUN npm install gulp@^3.8.10 -g

COPY . /app/
RUN gulp stylus

EXPOSE 4000
