# Contribution guide

First of all, thank you for taking the time to contribute! 🎉

When contributing to [pre-dokku-server-setup](https://github.com/engineervix/pre-dokku-server-setup), please first create an [issue](https://github.com/engineervix/pre-dokku-server-setup/issues) to discuss the change you wish to make before making a change.

## Before making a pull request

1. Fork [the repository](https://github.com/engineervix/pre-dokku-server-setup).
2. Clone the repository from your GitHub.
3. Check out a new branch and add your modification.
4. Run [shellcheck](https://www.shellcheck.net/): `bash -c 'shopt -s globstar; shellcheck ./*.sh'` and ensure that it completes with an `exit 0` status. If your changes have introduced some warnings, please try and address them. If you have good reason to ignore some of them, then mention this in the "longer description" portion of your commit.
5. Update `README.md` for your changes.
6. Commit your changes, and appropriately categorize your commit based on the [Conventional Commits Specification](https://www.conventionalcommits.org/en/v1.0.0/).
7. Send a [pull request](https://github.com/engineervix/pre-dokku-server-setup/pulls) 🙏
