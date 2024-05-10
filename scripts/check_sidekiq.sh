#!/bin/bash

# Check if the pid exists, only work if we start sidekiq using
# script/start_sidekiq.sh script
pid=$(ps aux | pgrep -f '[s]idekiq')
echo "Sidekiq pid: $pid"
if [[ -z "${pid// }" ]]; then
  echo "Sidekiq process not started!"
  exit 1
fi

# Check process status based on its title
sidekiqstatus=$(ps -o command -p $pid)
if [[ -z "${sidekiqstatus// }" ]]; then
  echo "Sidekiq process not found!"
  exit 1
fi

# The process is not ready yet
if ! [[ $sidekiqstatus =~  ^.*busy.*$ ]]; then
  echo "Sidekiq is not ready!"
  exit 1
fi

# The process is stopping
if [[ $sidekiqstatus =~ ^.*stopping.*$ ]]; then
  echo "Sidekiq is stopping!"
  exit 1
fi

echo "Sidekiq is running!"
# Other cases
exit 0
