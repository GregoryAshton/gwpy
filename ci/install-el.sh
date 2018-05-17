#!/bin/bash
# Copyright (C) Duncan Macleod (2017)
#
# This file is part of GWpy.
#
# GWpy is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GWpy is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GWpy.  If not, see <http://www.gnu.org/licenses/>.

#
# Build RedHat (Enterprise Linux) packages
#

# get python3 version
. ci/lib.sh
PYTHON3_VERSION=$(get_python3_version)
PY3XY=${PYTHON3_VERSION/./}

# update system
yum -yq update

# install sdist dependencies
yum -yq install \
    rpm-build \
    git \
    python2-pip \
    python-jinja2 \
    GitPython

# install build dependencies
yum -yq install \
    python-rpm-macros \
    epel-rpm-macros \
    python3-rpm-macros \
    python2-setuptools \
    python${PY3XY}-setuptools

GWPY_VERSION=$(python setup.py --version)

# upgrade setuptools for development builds only to prevent version munging
if [[ "${GWPY_VERSION}" == *"+"* ]]; then
    pip install "setuptools>=25"
fi

# build the RPM using tarball
python setup.py sdist
rpmbuild --define "_rpmdir $(pwd)/dist" -tb dist/gwpy-*.tar.gz

# install the rpm
if [ ${PY_XY} -lt 30 ]; then
    GWPY_RPM="dist/noarch/python2-gwpy-*.noarch.rpm"  # install python2 only
else
    GWPY_RPM="dist/noarch/python*-gwpy-*.noarch.rpm"  # install both 2 and 3
fi
yum -yq --nogpgcheck localinstall ${GWPY_RPM}

# install system-level extras
yum -yq install \
    nds2-client-${PY_PREFIX} \
    ldas-tools-framecpp-${PY_PREFIX} \
    lalframe-${PY_PREFIX} \
    lalsimulation-${PY_PREFIX} \
    h5py \
|| true

# HACK: fix missing file from ldas-tools-framecpp
if [ ! -f /usr/lib64/$PYTHON/site-packages/LDAStools/__init__.py ]; then
    touch /usr/lib64/$PYTHON/site-packages/LDAStools/__init__.py
fi

# install system-level extras that might use python2- prefix
if [ ${PY_XY} -lt 30 ]; then
    yum -yq install python2-root
else
    yum -yq install ${PY_PREFIX}-root
fi
