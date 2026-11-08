#!/bin/bash
# Rebuilds every ACS course file (assets/data/acs/*.json) from tool/acs/.
# Needs bash and gcc (USO, PCLP, SD are checked against them) and, for MN and
# ELTH, a python with numpy: PY=/path/to/python tool/acs/build_all.sh
set -e
cd "$(dirname "$0")/../.."
PY=${PY:-python3}
for c in uso iocla pclp sd pl math_courses fizica; do python3 -I tool/acs/$c.py; done
for c in mn elth; do $PY -I tool/acs/$c.py; done
