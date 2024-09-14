#!/bin/bash

export PROJECT_ROOT="${PWD}"
export DV_ROOT="${PROJECT_ROOT}/dv"
export RTL_ROOT="${PROJECT_ROOT}/rtl"
export SCRIPTS_ROOT="${PROJECT_ROOT}/scripts"

export DV_REGRESSION_LISTS_DIR="${DV_ROOT}/regressions"
export DV_MODELS="${DV_ROOT}/model"
export DV_DPI_C="${DV_MODELS}/dpi-c"

export WORKDIR="${PROJECT_ROOT}/work"
export REGRDIR="${PROJECT_ROOT}/regr"
export PATH="${SCRIPTS_ROOT}:${PATH}"
