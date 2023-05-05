FROM buildpack-deps:focal

COPY install-packages /usr/bin

### base ###
ARG DEBIAN_FRONTEND=noninteractive

RUN yes | unminimize \
    && install-packages \
        zip \
        unzip \
        bash-completion \
        build-essential \
        ninja-build \
        htop \
        jq \
        less \
        locales \
        man-db \
        nano \
        software-properties-common \
        sudo \
        time \
        vim \
        multitail \
        lsof \
        ssl-cert \
        fish \
        zsh \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8

### Git ###
RUN add-apt-repository -y ppa:git-core/ppa \
    && install-packages git

### Codespace user ###
# '-l': see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
RUN useradd -l -u 33333 -G sudo -md /home/codespace -s /bin/bash -p codespace codespace \
    # passwordless sudo for users in the 'sudo' group
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers
ENV HOME=/home/codespace
WORKDIR $HOME
# custom Bash prompt
RUN { echo && echo "PS1='\[\e]0;\u \w\a\]\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \\\$ '" ; } >> .bashrc

### Codespace user (2) ###
USER codespace
# use sudo so that user does not get sudo usage info on (the first) login
RUN sudo echo "Running 'sudo' for Codespace: success" && \
    # create .bashrc.d folder and source it in the bashrc
    mkdir /home/codespace/.bashrc.d && \
    (echo; echo "for i in \$(ls \$HOME/.bashrc.d/*); do source \$i; done"; echo) >> /home/codespace/.bashrc

### Ruby ###
LABEL dazzle/layer=lang-ruby
LABEL dazzle/test=tests/lang-ruby.yaml
USER codespace
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
    && curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - \
    && curl -fsSL https://get.rvm.io | bash -s stable \
    && bash -lc " \
        rvm requirements \
        && rvm install 3.0.3 \
        && rvm use 3.0.3 --default \
        && rvm rubygems current \
        && gem install bundler --no-document" \
    && echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*' >> /home/codespace/.bashrc.d/70-ruby
RUN echo "rvm_gems_path=/home/codespace/.rvm" > ~/.rvmrc

ENV GEM_HOME=/workspaces/.rvm
ENV GEM_PATH=$GEM_HOME:$GEM_PATH
ENV PATH=/workspaces/.rvm/bin:$PATH

USER codespace
# AppDev stuff
RUN /bin/bash -l -c "gem install htmlbeautifier rufo -N"

# Install Google Chrome
RUN sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | \
    tee -a /etc/apt/sources.list.d/google.list' && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | \
    sudo apt-key add - && \
    sudo apt-get update && \
    sudo apt-get install -y google-chrome-stable libxss1

# Install Chromedriver (compatable with Google Chrome version)
#   See https://gerg.dev/2021/06/making-chromedriver-and-chrome-versions-match-in-a-docker-image/
# RUN BROWSER_MAJOR=$(google-chrome --version | sed 's/Google Chrome \([0-9]*\).*/\1/g') && \
#     wget https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${BROWSER_MAJOR} -O chrome_version && \
#     wget https://chromedriver.storage.googleapis.com/`cat chrome_version`/chromedriver_linux64.zip && \
#     unzip chromedriver_linux64.zip && \
#     sudo mv chromedriver /usr/local/bin/ && \
#     DRIVER_MAJOR=$(chromedriver --version | sed 's/ChromeDriver \([0-9]*\).*/\1/g') && \
#     echo "chrome version: $BROWSER_MAJOR" && \
#     echo "chromedriver version: $DRIVER_MAJOR" && \
#     if [ $BROWSER_MAJOR != $DRIVER_MAJOR ]; then echo "VERSION MISMATCH"; exit 1; fi
# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
RUN sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
RUN sudo apt-get -y update
RUN sudo apt-get -y install google-chrome-stable
# Install Chromedriver
# RUN sudo apt-get -y install google-chrome-stable
RUN wget https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip

RUN sudo mv chromedriver /usr/bin/chromedriver
RUN sudo chown root:root /usr/bin/chromedriver
RUN sudo chmod +x /usr/bin/chromedriver

# Install PostgreSQL
RUN sudo install-packages postgresql-12 postgresql-contrib-12

# Setup PostgreSQL server for user codespace
ENV PATH="$PATH:/usr/lib/postgresql/12/bin"
ENV PGDATA="/workspaces/.pgsql/data"
RUN mkdir -p ~/.pg_ctl/bin ~/.pg_ctl/sockets \
 && printf '#!/bin/bash\n[ ! -d $PGDATA ] && mkdir -p $PGDATA && initdb -D $PGDATA\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" start\n' > ~/.pg_ctl/bin/pg_start \
 && printf '#!/bin/bash\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" stop\n' > ~/.pg_ctl/bin/pg_stop \
 && chmod +x ~/.pg_ctl/bin/*
ENV PATH="$PATH:$HOME/.pg_ctl/bin"
ENV DATABASE_URL="postgresql://codespace@localhost"
ENV PGHOSTADDR="127.0.0.1"
ENV PGDATABASE="postgres"

# This is a bit of a hack. At the moment we have no means of starting background
# tasks from a Dockerfile. This workaround checks, on each bashrc eval, if the
# PostgreSQL server is running, and if not starts it.
RUN printf "\n# Auto-start PostgreSQL server.\n[[ \$(pg_ctl status | grep PID) ]] || pg_start > /dev/null\n" >> ~/.bashrc

WORKDIR /base-rails
USER codespace
RUN /bin/bash -l -c "sudo apt update && sudo apt install -y graphviz"
# Install fuser (bin/server) & expect (web_git)
RUN sudo apt install -y libpq-dev psmisc lsof expect

# Install Parity
RUN wget -qO - https://apt.thoughtbot.com/thoughtbot.gpg.key | sudo apt-key add - \
    && echo "deb http://apt.thoughtbot.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/thoughtbot.list \
    && sudo apt-get update \
    && sudo apt-get -y install parity

# Install Node and npm
RUN curl -fsSL https://deb.nodesource.com/setup_15.x | sudo -E bash - \
    && sudo apt-get install -y nodejs

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
    && sudo apt-get update \
    && sudo apt-get install -y yarn \
    && sudo npm install -g n \
    && sudo n 14 \
    && hash -r

WORKDIR /base-rails
COPY Gemfile /base-rails/Gemfile
COPY Gemfile.lock /base-rails/Gemfile.lock
COPY package.json /base-rails/package.json
COPY yarn.lock /base-rails/yarn.lock
# For some reason, the copied files were owned by root so bundle could not succeed
RUN /bin/bash -l -c "sudo chown -R $(whoami):$(whoami) Gemfile Gemfile.lock package.json yarn.lock"
RUN /bin/bash -l -c "gem install bundler:2.2.32 rufo htmlbeautifier --no-document"

RUN /bin/bash -l -c "mkdir gems && bundle config set --local path 'gems' && bundle install"
# Disable skylight dev warning
# RUN /bin/bash -l -c "skylight disable_dev_warning"

# Install JS dependencies
RUN /bin/bash -l -c "yarn install"

# Install heroku-cli
RUN /bin/bash -l -c "curl https://cli-assets.heroku.com/install.sh | sh"

# Git global configuration
RUN git config --global push.default upstream \
    && git config --global merge.ff only \
    && git config --global alias.acm '!f(){ git add -A && git commit -am "${*}"; };f' \
    && git config --global alias.as '!git add -A && git stash' \
    && git config --global alias.p 'push' \
    && git config --global alias.sla 'log --oneline --decorate --graph --all' \
    && git config --global alias.co 'checkout' \
    && git config --global alias.cob 'checkout -b'

# Alias 'git' to 'g'
RUN echo 'export PATH="$PATH:$PWD/bin"' >> ~/.bashrc
RUN echo "# No arguments: 'git status'\n\
# With arguments: acts like 'git'\n\
g() {\n\
  if [[ \$# > 0 ]]; then\n\
    git \$@\n\
  else\n\
    git status\n\
  fi\n\
}\n# Complete g like git\n\
source /usr/share/bash-completion/completions/git\n\
__git_complete g __git_main" >> ~/.bash_aliases

# Add current git branch to bash prompt
RUN echo "# Add current git branch to prompt\n\
parse_git_branch() {\n\
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \\\(.*\\\)/:(\\\1)/'\n\
}\n\
\n\
PS1='\[]0;\u \w\]\[[01;32m\]\u\[[00m\] \[[01;34m\]\w\[[00m\]\[\e[0;38;5;197m\]\$(parse_git_branch)\[\e[0m\] \\\$ '" >> ~/.bashrc

# Alias bundle exec to be
RUN echo "alias be='bundle exec'" >> ~/.bash_aliases

# Hack to pre-install bundled gems
RUN echo "rvm use 3.0.3" >> ~/.bashrc
RUN echo "rvm_silence_path_mismatch_check_flag=1" >> ~/.rvmrc
