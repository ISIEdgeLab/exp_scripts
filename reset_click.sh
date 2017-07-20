#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
${SCRIPTDIR}/reset_experiment.sh $* click
exit $?
