#!/bin/bash

__conda_setup="$('/usr/local/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/usr/local/etc/profile.d/conda.sh" ]; then
        . "/usr/local/etc/profile.d/conda.sh"
    else
        export PATH="/usr/local/bin:$PATH"
    fi
fi
unset __conda_setup

conda activate env