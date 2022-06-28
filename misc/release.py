#!/usr/bin/env python3

"""release.py

to help in managing releases using `standard-version`_.

Usage in this project:
    python misc/release.py [bump | notes]

.. _standard-version: https://github.com/conventional-changelog/standard-version
"""

import argparse
import os
import subprocess
import sys

# from pathlib import Path

# needed to read *.toml files
import tomli

# colorama is a commitizen dependency
from colorama import Fore, init

__author__ = "Victor Miti"
__copyright__ = "Copyright 2022, Victor Miti"
__license__ = "MIT"


def execute_bump_hack():
    """A little hack that combines commitizen-tools and standard-version

    commitizen-tools understands Python stuff, but I don't like the
    generated changelogs. I had no time to look at how to customize them, so I
    decided to use standard-version (from the Javascript world). Unfortunately,
    standard-version doesn't understand Python stuff, and since I didn't have
    time to write my own updater for python files and toml files, I have to
    make the two work together!

    This requires standard-version to be installed globally on your system:
    ``npm i -g standard-version``
    If you're setting it up for the first time on another project, you will probably
    encounter problems generating the entire changelog. See how Łukasz Nojek came up
    with a hack to deal with this:
    https://lukasznojek.com/blog/2020/03/how-to-regenerate-changelog-using-standard-version/

    The formula (workflow) is as follows:

    1. cz bump --files-only
    2. git add .cz.toml backup.sh
    3. standard-version --commit-all --release-as <result from cz if not none>
    4. git push --follow-tags origin main

    # TODO: add additional options here, which can passed to either cz or standard version
    """
    print(f"{Fore.MAGENTA}Attempting to bump using commitizen-tools ...{Fore.RESET}")
    os.system("cz bump --files-only > .bump_result.txt")
    str_of_interest = "increment detected: "
    result = ""
    with open(".bump_result.txt", "r") as br:
        for line in br:
            if str_of_interest in line:
                result = line
                break
    release_type = result.replace(str_of_interest, "").strip("\n").lower()
    print(f"cz bump result: {release_type}")
    if release_type == "none":
        print(f"{Fore.YELLOW}No increment detected, cannot bump{Fore.RESET}")
    elif release_type in ["major", "minor", "patch"]:
        print(f"{Fore.GREEN}Looks like the bump command worked!{Fore.RESET}")
        print(f"{Fore.GREEN}Now handing over to standard-version ...{Fore.RESET}")
        # first, stage the bumped files
        with open("pyproject.toml", "rb") as f:
            toml_dict = tomli.load(f)
        version_files = toml_dict["tool"]["commitizen"]["version_files"]
        files_to_add = " ".join(version_files)
        os.system(f"git add .cz.toml {files_to_add}")
        # now we can pass result to standard-release
        print(f"{Fore.GREEN}let me retrieve the tag we're bumping from ...{Fore.RESET}")
        # get_previous_tag = subprocess.getoutput(
        #     "git describe --abbrev=0 --tags `git rev-list --tags --skip=1  --max-count=1`"
        # )
        get_current_tag = subprocess.getoutput(
            "git describe --abbrev=0 --tags `git rev-list --tags --skip=0  --max-count=1`"
        )
        previous_tag = get_current_tag.stdout.rstrip()
        os.system(
            f'standard-version --commit-all --release-as {release_type} --releaseCommitMessageFormat "bump: ✈️ {previous_tag} → v{{{{currentTag}}}}"'
        )
        # push to origin
        os.system("git push --follow-tags origin main")
    else:
        print(
            f"{Fore.RED}Something went horribly wrong, please figure it out yourself{Fore.RESET}"
        )
        print(f"{Fore.RED}Bump failed!{Fore.RESET}")

    # clean up
    os.system("rm -vf .bump_result.txt")


def get_release_notes():
    """extract content from CHANGELOG.md for use in Github Releases

    we read the file and loop through line by line
    we wanna extract content beginning from the first Heading 2 text
    to the last line before the next Heading 2 text
    """
    pattern_to_match = "## [v"

    count = 0
    lines = []
    heading_text = "## What's changed in this release\n"
    lines.append(heading_text)

    with open("CHANGELOG.md", "r") as c:
        for line in c:
            if pattern_to_match in line and count == 0:
                count += 1
            elif pattern_to_match not in line and count == 1:
                lines.append(line)
            elif pattern_to_match in line and count == 1:
                break

    # home = str(Path.home())
    # release_notes = os.path.join(home, "LATEST_RELEASE_NOTES.md")
    release_notes = os.path.join("../", "LATEST_RELEASE_NOTES.md")
    with open(release_notes, "w") as f:
        print("".join(lines), file=f, end="")


def release(args=None):
    """Console script entry point"""

    if not args:
        args = sys.argv[1:]

    parser = argparse.ArgumentParser(
        prog="release",
        description="to help in managing releases using standard-version",
    )

    parser.add_argument(
        "operation", help="The operation to perform [ bump | notes ].", type=str
    )

    args = parser.parse_args(args)

    init()

    if args.operation in ["bump", "notes"]:
        if args.operation == "bump":
            execute_bump_hack()
        else:
            get_release_notes()
    else:
        print("accepted operations: bump | notes")
        print("please try again")
        sys.exit(1)


if __name__ == "__main__":
    unstaged_str = "not staged for commit"
    uncommitted_str = "to be committed"
    check = subprocess.getoutput("git status")
    if unstaged_str not in check or uncommitted_str not in check:
        release()
    else:
        print("Sorry mate, please ensure there are no pending git operations")
