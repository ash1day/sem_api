FROM ruby:2.3.1-slim

MAINTAINER "Toshiki Inami <t-inami@arukas.io>"

# Install curl, git and the other libraries
RUN apt-get clean && apt-get update && apt-get install -y \
      git \
      # wget \
      # ca-certificates \
      libyaml-dev \
      libssl-dev \
      libreadline-dev \
      libxml2-dev \
      libxslt1-dev \
      libffi-dev \
      build-essential \
      # r-base \
      r-base-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the applilcation directory
WORKDIR /app

# RUN wget https://rforge.net/snapshot/Rserve_1.8-5.tar.gz
# RUN R CMD INSTALL Rserve_1.8-5.tar.gz

# Install gems
COPY Gemfile /app
RUN bundle install

# Copy our code from the current folder to /app inside the container
COPY . /app

# Make port 4657 available for publish
EXPOSE 4567

# Start server
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]
