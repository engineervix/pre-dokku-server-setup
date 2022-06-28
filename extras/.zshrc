# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/root/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  colored-man-pages
  colorize
  command-not-found
	common-aliases
  docker
  docker-compose
  extract
  git
  git-extras
  gitignore
  grunt
  gulp
  npm
  pip
  pyenv
  python
  rsync
  ssh-agent
  sudo
  tmux
  web-search
  yarn
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Add custom scripts to PATH
export PATH="$PATH:$HOME/bin"

# --------- Custom Functions --------- #

# best compression:
# tar cv path/to/dir/ | xz -3e > compressed_file.tar.xz

tar_max() {
  tar cv "$1" | xz -3e > "$2".tar.xz
}

# search for string in files
grep_this() {
  grep --color -inrw . -e "$1"
  printf "\033[0;36m=================================================================\033[0m\n"
  echo "Matches: " $(grep --color -inrw . -e "$1" | wc -l)
  printf "\033[1;36m=================================================================\033[0m\n"
}

# create directory with today's date as dir_name in format YYYY-mmm-dd-day
mkdir_date() {
  mkdir -p $(date '+%Y-%h-%d-%a')
}

mkv_to_mp4() {
  # ffmpeg -i "$1" -c:v libx264 -c:a aac -b:a 128k "${1%.*}".mp4
  ffmpeg -i "$1" -c:v libx264 -c:a aac "${1%.*}".mp4
}

merge_mp4_m4a() {
  # argument variables: 1. video file, 2. audio file
  ffmpeg -i "$1" -i "$2" -c:v copy -c:a copy "${1%.*}"_merged.mp4
}

merge_webm_m4a() {
  # argument variables: 1. video file, 2. audio file
  ffmpeg -i "$1" -i "$2" -c:v copy -c:a copy "${1%.*}"_merged.mkv
}

# Pass the image width (in pixels) as the first argument,
# and the quality (in %) as the second argument; for instance:
# img_resize 1200 85
img_resize() {
  mkdir resized
  mkdir src
  mv -v *.jpg src/
  cd src/
  for f in *.jpg; do
    convert -resize "$1"x ./"$f" -quality "$2" -verbose ../resized/"${f%.jpg}.jpg"
  done
  cd ..
}

concat_two_videos() {
  ffmpeg -i "$1" -c copy -bsf:v h264_mp4toannexb -f mpegts intermediate1.ts
  ffmpeg -i "$2" -c copy -bsf:v h264_mp4toannexb -f mpegts intermediate2.ts
  ffmpeg -i "concat:intermediate1.ts|intermediate2.ts" -c copy -bsf:a aac_adtstoasc __concatenated_output.mp4
  rm -v intermediate1.ts
  rm -v intermediate2.ts
}

# the following function renames files by replacing spaces with underscores
# usage: kill_spaces ext
# where ext is the filetype extension, for example, pdf
kill_spaces() {
  find . -name "**.$1" -type f -print0 | while read -d $'\0' f; do mv -v "$f" "${f// /_}"; done
}

wget_entire_site() {
  wget --continue --mirror --convert-links --adjust-extension --page-requisites --no-parent "$1"
}

# encrypt pdf, allow printing
encrypt_pdf() {
  encrypted_pdf="${1%.pdf}.128.pdf"
  pdftk "$1" output ${encrypted_pdf} owner_pw "$2" allow printing verbose

  # rename the files after encryption
  mv -v "$1" "${1%.pdf}_src.pdf"
  mv -v ${encrypted_pdf} "${encrypted_pdf%.128.pdf}.pdf"
}

# split pdf
split_pdf() {
  split_files="${1%.pdf}_%02d.pdf"
  pdftk "$1" burst output ${split_files} verbose
}

# download audio from youtube
fetch_audio() {
  youtube-dl --output "%(title)s.%(ext)s" --extract-audio --audio-format mp3 --audio-quality 0 "$1"
}

# download high quality mp4 video from youtube
yt_mp4() {
	youtube-dl -c -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' "$1"
}

# search a bunch of pdf files in the $(pwd) for selected text
grep_pdf() {
  # find . -name '*.pdf' -exec sh -c 'pdftotext "{}" - | grep --with-filename --label="{}" --color -i "Using the BIV"' \;
  find . -iname '*.pdf' | while read filename
  do
    pdftotext -enc Latin1 "$filename" - | grep --with-filename --label="$filename" --color -i "$1"
  done
}

export VISUAL=vim
export EDITOR="$VISUAL"

# tinypng
export TINYPNG_API_KEY=''

# sendgrid
export SENDGRID_API_KEY=''

# snap
export PATH="$PATH:/snap/bin"

# pyenv
# export PATH="$HOME/.pyenv/bin:$PATH"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"

# https://github.com/athityakumar/colorls
source $(dirname $(gem which colorls))/tab_complete.sh

if [ -x "$(command -v colorls)" ]; then
    alias ls="colorls"
    alias la="colorls -alh"
fi

# Fix for the error:
## gpg: signing failed: Inappropriate ioctl for device
## gpg: [stdin]: clear-sign failed: Inappropriate ioctl for device
# source: https://tutorials.technology/solved_errors/21-gpg-signing-failed-Inappropriate-ioctl-for-device.html
export GPG_TTY=$(tty)
