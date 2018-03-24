# name: scorphish++
function tbytes -d 'calculates the total size of the files in the current directory'
  set -l tBytes (ls -al | grep "^-" | awk 'BEGIN {i=0} { i += $5 } END { print i }')

  if test $tBytes -lt 1048576
    set -g total (echo -e "scale=1 \n$tBytes/1048 \nquit" | bc)
    set -g units "Kb"
  else
    set -g total (echo -e "scale=1 \n$tBytes/1048576 \nquit" | bc)
    set -g units "Mb"
  end
  echo -n "$total$units"
end


function _prompt_rubies -a sep_color -a ruby_color -d 'Display current Ruby (rvm/rbenv)'
  [ "$theme_display_ruby" = 'no' ]; and return
  set -l ruby_version
  if type rvm-prompt >/dev/null 2>&1
    set ruby_version (rvm-prompt i v g)
  else if type rbenv >/dev/null 2>&1
    set ruby_version (rbenv version-name)
  end
  [ -z "$ruby_version" ]; and return

  echo -n -s $sep_color '|' $ruby_color (echo -n -s $ruby_version | cut -d- -f2-)
end

function _prompt_virtualfish -a sep_color -a venv_color -d "Display activated virtual environment (only for virtualfish, virtualenv's activate.fish changes prompt by itself)"
  [ "$theme_display_virtualenv" = 'no' ]; and return
  echo -n -s $sep_color '|' $venv_color $PYTHON_VERSION
  [ -n "$VIRTUAL_ENV" ]; and echo -n -s '@'(basename "$VIRTUAL_ENV")
end

function _prompt_nvm -a sep_color -a nvm_color -d "Display current activated Node"
  [ "$theme_display_nvm" != 'yes' -o -z "$NVM_VERSION" ]; and return
  echo -n -s $sep_color '|' $nvm_color $NVM_VERSION
end

function _prompt_whoami -a sep_color -a whoami_color -a machine_color -d "Display user@host if on a SSH session"
  echo -n -s $whoami_color (whoami) $sep_color ' on ' $machine_color (hostname|cut -d . -f 1) $sep_color ' at '
end

function _git_branch_name
  echo (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
  echo (command git status -s --ignore-submodules=dirty ^/dev/null)
end

function _git_ahead_count -a remote -a branch_name
  echo (command git log $remote/$branch_name..HEAD ^/dev/null | \
    grep '^commit' | wc -l | tr -d ' ')
end

function _git_dirty_remotes -a remote_color -a ahead_color
  set current_branch (command git rev-parse --abbrev-ref HEAD ^/dev/null)
  set current_ref (command git rev-parse HEAD ^/dev/null)

  for remote in (git remote | grep 'origin\|upstream')

    set -l git_ahead_count (_git_ahead_count $remote $current_branch)

    set remote_branch "refs/remotes/$remote/$current_branch"
    set remote_ref (git for-each-ref --format='%(objectname)' $remote_branch)
    if test "$remote_ref" != ''
      if test "$remote_ref" != $current_ref
        if [ $git_ahead_count != 0 ]
          echo -n "$remote_color!"
          echo -n "$ahead_color+$git_ahead_count$normal"
        end
      end
    end
  end
end

function fish_prompt
  set -l exit_code $status

  set -l gray (set_color 666)
  set -l blue (set_color blue)
  set -l red (set_color red)
  set -l normal (set_color normal)
  set -l yellow (set_color ffcc00)
  set -l orange (set_color ffb300)
  set -l green (set_color green)

  set_color -o 666
  _prompt_whoami $gray $green $orange

  set_color -o cyan
  printf '%s ' (prompt_pwd)
  set_color -o 666
  printf '['

  echo -n $blue~(tbytes)
  if [ "$VIRTUAL_ENV" != "$LAST_VIRTUAL_ENV" -o -z "$PYTHON_VERSION" ]
    set -gx PYTHON_VERSION (python --version 2>&1 | cut -d\  -f2)
    set -gx LAST_VIRTUAL_ENV $VIRTUAL_ENV
  end
  _prompt_virtualfish $gray $blue

  _prompt_rubies $gray $red

  if [ "$NVM_BIN" != "$LAST_NVM_BIN" -o -z "$NVM_VERSION" ]
    set -gx NVM_VERSION (node --version)
    set -gx LAST_NVM_BIN $NVM_BIN
  end

  _prompt_nvm $gray $green

  set_color -o 666
  # Show git branch and dirty state
  if [ (_git_branch_name) ]
    set -l git_branch (_git_branch_name)

    set dirty_remotes (_git_dirty_remotes $red $orange)

    if [ (_is_git_dirty) ]
      echo -n -s $gray '|' $yellow $git_branch $red '*' $dirty_remotes $normal
    else
      echo -n -s $gray '|' $yellow $git_branch $red $dirty_remotes $normal
    end
  end

  if test $exit_code -ne 0
    set arrow_colors 600 900 c00 f00
  else
    set arrow_colors 060 090 0c0 0f0
  end

  printf ']\n '

  for arrow_color in $arrow_colors
    set_color $arrow_color
    printf '»'
  end

  printf ' '

  set_color normal
end
