FROM ruby:2.3.1-slim

MAINTAINER "Yoshihiro Ashida <y4ashida@gmail.com>"

# Install curl, git and the other libraries
RUN apt-get clean && apt-get update
RUN apt-get install -y \
      git \
      libyaml-dev \
      libssl-dev \
      libreadline-dev \
      libxml2-dev \
      libxslt1-dev \
      libffi-dev \
      build-essential
RUN apt-get install -y r-base
RUN rm -rf /var/lib/apt/lists/*

# Set the applilcation directory
WORKDIR /app

# RUN wget https://rforge.net/snapshot/Rserve_1.8-5.tar.gz
# RUN R CMD INSTALL Rserve_1.8-5.tar.gz

# Copy our code from the current folder to /app inside the container
COPY . /app
RUN bundle install
RUN Rscript install_dependencies.r

# Make port 4657 available for publish
EXPOSE 4567

# Start server
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]
