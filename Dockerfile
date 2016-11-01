FROM rocker/r-base:latest

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
      build-essential \
      ruby-dev
RUN rm -rf /var/lib/apt/lists/*

# Set the applilcation directory
WORKDIR /app

# Copy our code from the current folder to /app inside the container
COPY . /app
RUN gem i bundle
RUN bundle
RUN su - -c "R -e \"install.packages('lavaan', dependencies=TRUE, repos='http://cran.at.r-project.org/')\""

# Make port 4657 available for publish
EXPOSE 4567

# Start server
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "80"]
