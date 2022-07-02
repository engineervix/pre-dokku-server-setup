# Changelog

All notable changes to this project will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project attempts to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.1.0 (2022-07-02)

### 🚀 Features

- welcome to pre-dokku-server-setup 🚀 ([f82fede](https://github.com/engineervix/pre-dokku-server-setup/commit/f82fedeff9a608e1563805ea12f233aadbf6a7e9))

### ✅ Tests

- change `getopts "s"` to `getopts "skip"` ([e5dce04](https://github.com/engineervix/pre-dokku-server-setup/commit/e5dce04a5f80fba50833bb4f2c9b931a7cead971))
- fix broken unit tests and change test timezone to Africa/Lusaka ([6055310](https://github.com/engineervix/pre-dokku-server-setup/commit/60553106c9de9aed63c3310f7ed20f730f593055))

### 👷 CI/CD

- add bunit.shl ([f31531f](https://github.com/engineervix/pre-dokku-server-setup/commit/f31531f82475c800c56abb99e5dfc92b026f9962))
- remove submodules setup step and checkout with submodules true option ([c62debc](https://github.com/engineervix/pre-dokku-server-setup/commit/c62debc7855454eb13d4bf8cd0e08a02e975c402))
- rename workflow to Shellcheck ([bb6a4f1](https://github.com/engineervix/pre-dokku-server-setup/commit/bb6a4f1ee63b2d3b7efcdd8dd5f6a960d9f0313e))
- revert e5dce04 and update test command ([7ba6b46](https://github.com/engineervix/pre-dokku-server-setup/commit/7ba6b46801e07303e361bea337195c563c5d9652))
- run `sudo apt-get update` before installing systemd-timesyncd ([133ee6d](https://github.com/engineervix/pre-dokku-server-setup/commit/133ee6dc0ad55926586b350e9c09c84b853cb0cb))
- set submodules: recursive for actions/checkout@v2 ([a184e7e](https://github.com/engineervix/pre-dokku-server-setup/commit/a184e7ed0d75ae20a9986db4e847e0a205ab032d))
- use actions/checkout@v3 ([6699a99](https://github.com/engineervix/pre-dokku-server-setup/commit/6699a9926618e4c8a6de4601ad6cbdfafcc51da9))

### ⚙️ Build System

- update .gitmodules to use SSH instead of HTTPS ([defe60c](https://github.com/engineervix/pre-dokku-server-setup/commit/defe60c9806f06efc2df8075db59013b475cd7e7))

### ♻️ Code Refactoring

- fix shellcheck issues ([2dc015e](https://github.com/engineervix/pre-dokku-server-setup/commit/2dc015e91ae775e58f0eb1b5a03641d3f4ec7688))
- remove firefox from extra packages ([938d472](https://github.com/engineervix/pre-dokku-server-setup/commit/938d47211159d740c92be7806d1bc9944281ddf5))
- remove TINYPNG API Key and SENDGRID/MAILJECT API variables ([8edbea5](https://github.com/engineervix/pre-dokku-server-setup/commit/8edbea5f014adbb3cab3c94e2dda4455eb9e101b))
- split the configureSystemUpdatesAndLogs function into two ([ca33a8d](https://github.com/engineervix/pre-dokku-server-setup/commit/ca33a8d0c48c0962b20c04dcf84b4f06beb76c59))
- update setup script so that it uses argparse.bash ([dafe3a8](https://github.com/engineervix/pre-dokku-server-setup/commit/dafe3a80e6a37bc71a4565f5b58406c62b279606))

### 🐛 Bug Fixes

- install rkhunter only when POstfix is to be installed ([67c7bda](https://github.com/engineervix/pre-dokku-server-setup/commit/67c7bdac8aeaae01dc78fd49c16e2f4994e592ed))
- install snap if not exists ([fda6cb6](https://github.com/engineervix/pre-dokku-server-setup/commit/fda6cb6cb2aefb53324c95cab1b286f124564419))
- properly setup the submodules ([a8e9a08](https://github.com/engineervix/pre-dokku-server-setup/commit/a8e9a086c79ba593c7b5096a1186fb4c53378190))
- remove `-p` option on read command while getting mail settings ([0457c4d](https://github.com/engineervix/pre-dokku-server-setup/commit/0457c4d77cac3c60b4c407eeec1835631490a160))
- remove erroneous usage of ` >&3` ([0158710](https://github.com/engineervix/pre-dokku-server-setup/commit/01587109beae3dea68a4bc29ae30118999c42d8a))
- replace `ubuntu-server-setup` with pre-dokku-server-setup` ([648a1d4](https://github.com/engineervix/pre-dokku-server-setup/commit/648a1d4332a18c99a20bc044877239c9add1e28d))
- use python3 instead of python ([1bdad2b](https://github.com/engineervix/pre-dokku-server-setup/commit/1bdad2b9575d7cacb1ce5ed5d5528d439c358678))

### 📝 Docs

- add a TODO section, remove "not tested" warning ([cd68182](https://github.com/engineervix/pre-dokku-server-setup/commit/cd681824ac87472ba54a20416895eeb901e9ad12))
- add Dokku setup reference links, use one-liner for mail test ([088a1b6](https://github.com/engineervix/pre-dokku-server-setup/commit/088a1b6b32d5844e625dc1de8d3c50827289699a))
- improve clarity on --help option ([c8dd43e](https://github.com/engineervix/pre-dokku-server-setup/commit/c8dd43e4fb11b65de4fd92a83d3cd5941caa6a08))
- refine docs and remove warning ([878d64f](https://github.com/engineervix/pre-dokku-server-setup/commit/878d64ffe6ee2a83fb5245cb1e5d8a3c545e8272))
- update README ([dfe4161](https://github.com/engineervix/pre-dokku-server-setup/commit/dfe416197b759a42786c7730a558592a37296033))
