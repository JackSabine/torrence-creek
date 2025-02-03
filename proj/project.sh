#!/bin/bash

export WORKAREA="${PWD}"
export DV_ROOT="${WORKAREA}/dv"
export RTL_ROOT="${WORKAREA}/rtl"
export SCRIPTS_ROOT="${WORKAREA}/scripts"

export DV_REGRESSION_LISTS_DIR="${DV_ROOT}/regressions"
export DV_MODELS="${DV_ROOT}/model"
export DV_DPI_C="${DV_MODELS}/dpi-c"

export WORKDIR="${WORKAREA}/work"
export REGRDIR="${WORKAREA}/regr"
export PATH="${SCRIPTS_ROOT}:${PATH}"
