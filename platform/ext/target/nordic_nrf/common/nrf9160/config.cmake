#-------------------------------------------------------------------------------
# Copyright (c) 2020, Nordic Semiconductor ASA.
# Copyright (c) 2020-2021, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#-------------------------------------------------------------------------------

include(${PLATFORM_PATH}/common/core/config.cmake)

set(SECURE_UART1                        ON         CACHE BOOL      "Enable secure UART1")
set(PSA_API_TEST_TARGET                 "nrf9160"  CACHE STRING    "PSA API test target")
set(ITS_NUM_ASSETS                      "5"        CACHE STRING    "The maximum number of assets to be stored in the Internal Trusted Storage area")
set(NRF_NS_STORAGE                      OFF        CACHE BOOL      "Enable non-secure storage partition")
set(TFM_ITS_ENC_NONCE_LENGTH            "12"       CACHE STRING    "The size of the nonce used in ITS encryption in bytes")
set(TFM_ITS_AUTH_TAG_LENGTH             "16"       CACHE STRING    "The size of the tag used in ITS encryption in bytes")
