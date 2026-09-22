# Setup

Run `./install.sh` to set up everything below in one go (safe to re-run;
anything already in place is left alone, anything else in the way is
backed up first).

## Gitignore

```
git config --global core.excludesFile /Users/$USER/code/qsweber/dotfiles/src/gitignore.txt
```

## VSCode

```
ln -s /Users/$USER/code/qsweber/dotfiles/src/vscode_user_settings.json /Users/$USER/Library/Application\ Support/Code/User/settings.json
```

## ZSH

```
ln -s /Users/$USER/code/qsweber/dotfiles/src/zshrc.sh /Users/$USER/.zshrc
```

## Claude Code

```
ln -s /Users/$USER/code/qsweber/dotfiles/src/claude_settings.json /Users/$USER/.claude/settings.json
```
