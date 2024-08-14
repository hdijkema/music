#!/bin/bash
while [ 1 ]
do
   /usr/bin/cpufreq-set -c 0 -g powersave
   /usr/bin/cpufreq-set -c 1 -g powersave
   /usr/bin/cpufreq-set -c 2 -g powersave
   /usr/bin/cpufreq-set -c 3 -g powersave
  sleep 120
done
