# Ubuntu Server Setup for Dokku

Still a work in progress ...

> Initial Ubuntu VPS server setup prior to installation of [Dokku](https://dokku.com/).

## Introduction

This script uses Jason Hee's excellent [Ubuntu setup script](https://github.com/jasonheecs/ubuntu-server-setup) as a starting point for provisioning Ubuntu Servers in preparation for installation of [Dokku](https://dokku.com/).

**Why not just use Jason Hee's script**?

Jason Hee's script is perfect! What this script does is that it adds some extra things that such as ...

- [Zsh](https://www.zsh.org/), [ohmyzsh](https://ohmyz.sh) + [some fancy terminal enhancements](https://github.com/athityakumar/colorls)
- [Custom Vim Distribution](https://github.com/carlhuda/janus)
- [tmux](https://github.com/tmux/tmux/wiki)
- Optional [Postfix](http://www.postfix.org/) setup with either [Sendgrid](https://sendgrid.com/) or [MailJet](https://www.mailjet.com/)
- [Automatic Security Updates](https://help.ubuntu.com/community/AutomaticSecurityUpdates)
- [Logwatch](https://ubuntu.com/server/docs/logwatch)
- [fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page) and a few other security features
- and more.

... so if you're not interested in these things and just want to quickly get up and running with Dokku, then use Jason Hee's script.

**Note**: the script doesn't install Dokku, you have to restart the server after running this script, and login as the newly created user, then install Dokku:

```bash
# v0.27.6 was the latest tag at the time this README was initially written
# change to whatever the latest version will be when you read this
wget https://raw.githubusercontent.com/dokku/dokku/v0.27.6/bootstrap.sh && \
sudo DOKKU_TAG=v0.27.6 bash bootstrap.sh
```

## Getting Started

...

# TODO

- [ ] figure out how to let user decide on sendgrid/mailjet
- [ ] figure out how to allow user decide on installation of texlive or not
- [ ] finish up these docs
