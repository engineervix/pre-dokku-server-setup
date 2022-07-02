# Ubuntu Server Setup for Dokku

> Initial Ubuntu VPS server setup prior to installation of [Dokku](https://dokku.com/).

[![ShellCheck](https://github.com/engineervix/pre-dokku-server-setup/actions/workflows/main.yml/badge.svg)](https://github.com/engineervix/pre-dokku-server-setup/actions/workflows/main.yml)
[![last commit](https://img.shields.io/github/last-commit/engineervix/pre-dokku-server-setup)](https://github.com/engineervix/pre-dokku-server-setup/commits/)
[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)
![License](https://img.shields.io/github/license/engineervix/pre-dokku-server-setup)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [Post setup actions](#post-setup-actions)
- [Supported Ubuntu versions](#supported-ubuntu-versions)
- [Running tests](#running-tests)
- [Author](#author)
- [Contributing 🤝](#contributing-)
- [Show your support](#show-your-support)
- [License 📝](#license-)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Introduction

This script uses Jason Hee's excellent [Ubuntu setup script](https://github.com/jasonheecs/ubuntu-server-setup) as a starting point for provisioning Ubuntu Servers in preparation for installation of [Dokku](https://dokku.com/).

**Why not just use Jason Hee's script 🤔**?

Jason Hee's script is perfect! What this script does is that it adds a bunch of extra useful things such as ...

- [Zsh](https://www.zsh.org/), [ohmyzsh](https://ohmyz.sh) + [some fancy terminal enhancements](https://github.com/athityakumar/colorls)
- [Custom Vim Distribution](https://github.com/carlhuda/janus)
- [tmux](https://github.com/tmux/tmux/wiki)
- Optional [Postfix](http://www.postfix.org/) setup with either [Sendgrid](https://sendgrid.com/) or [MailJet](https://www.mailjet.com/)
- [Automatic Security Updates](https://help.ubuntu.com/community/AutomaticSecurityUpdates)
- [Logwatch](https://ubuntu.com/server/docs/logwatch)
- [fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page) and a few other security features
- and more.

... so if you're not interested in these things and just want to quickly get up and running with Dokku, then use Jason Hee's script.

**Note**: the script doesn't install Dokku, you have to restart the server after running this script, and login as the newly created user, then install Dokku like this:

```bash
# v0.27.6 was the latest tag at the time this README was initially written
# change to whatever the latest version will be when you read this
wget https://raw.githubusercontent.com/dokku/dokku/v0.27.6/bootstrap.sh && \
sudo DOKKU_TAG=v0.27.6 bash bootstrap.sh
```

## Getting Started

1. spin up a VPS using your preferred service provider ([DigitalOcean](https://www.digitalocean.com/), [Hetzner](https://www.hetzner.com/), [Linode](https://www.linode.com/), [Vultr](https://www.vultr.com/), etc.), ensuring that you
   - set the server's hostname to the domain that you'll be using as [global domain on Dokku](https://dokku.com/docs/configuration/domains/). This will ensure `/etc/hostname` and the `hostname` command respond correctly (something Dokku relies on).
   - specify an SSH key when bootstrapping your VPS
2. Configure DNS.
   - You'll need an A record for the naked domain (the "`@`" one) pointing to your IP with the lowest TTL possible
   - You'll need a wildcard A record (use '`*`') pointing to your IP with the lowest TTL possible
3. SSH into your server, clone this repository (& submodules) into your home directory, and run the setup script:

   ```bash
   cd ~
   git clone --recurse-submodules https://github.com/engineervix/pre-dokku-server-setup.git \
   && cd pre-dokku-server-setup \
   && bash setup.sh
   ```

   **Note**: If you run the script with no arguments, it will neither setup `postfix` on your server nor download `texlive-full`. The following optional arguments are available (for help, you can simply run `bash setup.sh -h` or `bash setup.sh --help`):

   ```shell
   --mailjet   # setup postfix with MailJest
   --sendgrid  # setup postfix with Sendgrid
   --texlive   # install texlive-full
   ```

   **Note**: if you select both `--mailjet` and `--sendgrid`, the script will terminate with an `exit 1` code, and you'd have to try again.

When the setup script is run, you will be prompted

- to enter the username of the new user account
- to add a public ssh key (which should be from your local machine) for the new account. You can display it on your local terminal via (assuming it's called `id_rsa.pub` and it's in the `~/.ssh/` directory.

  Feel free to change the path / name if you saved it in a different location / named it differently) ...

  ```bash
  cat ~/.ssh/id_rsa.pub
  ```

  ... then copy it and paste it in the terminal on your server.

  **Note** » If you don't have an existing key and you would like to generate one, or perhaps you already have one and would like to generate another ssh key from your local machine:

  ```bash
  ssh-keygen -t rsa
  ```

- to specify a [timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for the server. It will be set to 'Africa/Lusaka' if you do not specify a value.
- When setting up Postfix and configuring System Updates and Notification Settings, you'll be asked for

  - the System Administrator's email address (to **receive** notifications)
  - the email address that'll be associated with **send**ing emails. You need to use a Mailjet OR Sendgrid verified email address for this.

  > This script assumes that the email address you supply is associated with your Mailjet/Sendgrid domain. `myhostname` is therefore extracted from this email address. So, if your "mail_from" email address is josh@example.co.zm, then example.co.zm will be used as `myhostname` in the Postfix setup.

## Post setup actions

- [ ] Reboot and login as the new user
- [ ] Test your email configuration. See example below:

  Here's an example to test that your email works. I use the awesome [mail-tester.com](https://www.mail-tester.com) and with this configuration you should get a ~10/10 score. Remember to change **recipient@someplace.com** with whatever email address you'll get when you go to [mail-tester.com](https://www.mail-tester.com).

  ```bash
  echo "Hi there, this is my test message, and I am sending it to you\!" | mutt -s "Hello from your server" recipient@someplace.com
  ```

- [ ] On Ubuntu 22.04, you'll need to fix your vim config as follows: (see <https://github.com/amix/vimrc/issues/645#issuecomment-1120374288>)

  ```bash
  cd ~/.vim/janus/vim/tools/tlib/plugin/ && \
  git pull origin master
  ```

- [ ] Install Dokku, setup your projects and deploy 🚀. I created [this gist](https://gist.github.com/engineervix/8d1825a7301239e7c4df3af78aaee9a4) to serve as a goto reference for deploying (mostly Django) applications to Dokku.

  ```bash
  # v0.27.6 was the latest tag at the time this README was initially written
  # change to whatever the latest version will be when you read this
  ```

  ```bash
  wget https://raw.githubusercontent.com/dokku/dokku/v0.27.6/bootstrap.sh && \
  sudo DOKKU_TAG=v0.27.6 bash bootstrap.sh
  ```

  **Some excellent resources**:

  - [How to deploy Django project to Dokku](https://www.accordbox.com/blog/how-deploy-django-project-dokku/#introduction)
  - [Setting up Dokku with DigitalOcean and Namecheap (GitHub gist)](https://gist.github.com/djmbritt/10938092)
  - [Deploying an app with Dokku](https://vitobotta.com/2022/02/16/deploying-an-app-with-dokku/)
  - [Dokku Docs: Process Management](https://dokku.com/docs/processes/process-management/)
  - [Dokku Docs: Zero Downtime Deploys](https://dokku.com/docs/deployment/zero-downtime-deploys/)
  - [Dokku with Let's Encrypt behind Cloudflare](https://spiffy.tech/dokku-with-lets-encrypt-behind-cloudflare)
  - [Cloudflare certificates + Dokku](https://okhlopkov.com/cloudflare-certificates-dokku/)
  - [Securing Dokku with Let's Encrypt TLS Certificates](https://blog.semicolonsoftware.de/securing-dokku-with-lets-encrypt-tls-certificates/)

- [ ] [Fix `apt-key` Deprecation Warning on Ubuntu](https://www.omgubuntu.co.uk/2022/06/fix-apt-key-deprecation-error-on-ubuntu)

  In our case, it'll be something along these lines:

  ```bash
  sudo apt-key export 86E50310 | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/yarn.gpg && \
  sudo apt-key export 12576482 | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/lynis.gpg && \
  sudo apt-key export 288B3315 | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/dokku.gpg
  ```

  **Note**: better to first check with `sudo apt-key list`, as described in [How to Fix ‘apt-key’ Deprecation Warning on Ubuntu](https://www.omgubuntu.co.uk/2022/06/fix-apt-key-deprecation-error-on-ubuntu)

## Supported Ubuntu versions

Jason Hee's excellent [Ubuntu setup script](https://github.com/jasonheecs/ubuntu-server-setup) has been tested against Ubuntu 14.04, Ubuntu 16.04, Ubuntu 18.04, Ubuntu 20.04 and 22.04. However, this project primarily targets **Ubuntu 20.04** and **Ubuntu 22.04** (It'll most likely also work on **18.04**).

## Running tests

Tests are run against a set of Vagrant VMs. To run the tests, run the following in the project's directory:

`./tests/tests.sh`

## Author

👤 **Victor Miti**

- Blog: <https://importthis.tech>
- Twitter: [![Twitter: engineervix](https://img.shields.io/twitter/follow/engineervix.svg?style=social)](https://twitter.com/engineervix)
- Github: [@engineervix](https://github.com/engineervix)

## Contributing 🤝

Contributions, issues and feature requests are most welcome!

Feel free to check the [issues page](https://github.com/engineervix/pre-dokku-server-setup/issues) and take a look at the [contributing guide](CONTRIBUTING.md) before you get started

## Show your support

Please give a ⭐️ if you found this project helpful!

## License 📝

Copyright © 2022 [Victor Miti](https://github.com/engineervix).

This project is licensed under the terms of the [MIT](https://github.com/engineervix/pre-dokku-server-setup/blob/main/LICENSE) license.
