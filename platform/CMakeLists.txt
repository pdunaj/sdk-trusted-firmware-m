#-------------------------------------------------------------------------------
# Copyright (c) 2020-2021, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#-------------------------------------------------------------------------------
cmake_minimum_required(VERSION 3.15)
cmake_policy(SET CMP0076 NEW)
cmake_policy(SET CMP0079 NEW)

add_library(platform_s STATIC)
add_library(platform_region_defs INTERFACE)
add_library(platform_common_interface INTERFACE)

# under the multicore topology, NS is declared in the same place as the PSA
# interface so that it picks up the compiler definitions for the NS CPU
if(NOT TFM_MULTI_CORE_TOPOLOGY)
    add_library(platform_ns STATIC EXCLUDE_FROM_ALL)
endif()

if (BL2)
    add_library(platform_bl2 STATIC)
endif()

set(PLATFORM_DIR ${CMAKE_CURRENT_LIST_DIR})

add_subdirectory(ext/target/${TFM_PLATFORM} target)

#========================= Platform Common interface ==========================#

target_include_directories(platform_common_interface
    INTERFACE
        ./ext
        ./ext/cmsis
        ./ext/common
        ./ext/driver
        ./include
)

#========================= Platform Secure ====================================#

target_include_directories(platform_s
    PUBLIC
        $<$<BOOL:${CRYPTO_HW_ACCELERATOR}>:${CMAKE_CURRENT_SOURCE_DIR}/ext/accelerator/interface>
)

target_sources(platform_s
    PRIVATE
        $<$<BOOL:${TFM_PARTITION_PROTECTED_STORAGE}>:${CMAKE_CURRENT_SOURCE_DIR}/ext/common/tfm_hal_ps.c>
        $<$<BOOL:${TFM_PARTITION_INTERNAL_TRUSTED_STORAGE}>:${CMAKE_CURRENT_SOURCE_DIR}/ext/common/tfm_hal_its.c>
        ext/common/tfm_platform.c
        $<$<BOOL:${PLATFORM_DEFAULT_UART_STDOUT}>:${CMAKE_CURRENT_SOURCE_DIR}/ext/common/uart_stdout.c>
        $<$<BOOL:${TFM_SPM_LOG_RAW_ENABLED}>:ext/common/tfm_hal_spm_logdev_peripheral.c>
        $<$<BOOL:${TFM_EXCEPTION_INFO_DUMP}>:ext/common/exception_info.c>
        ext/common/tfm_hal_memory_symbols.c
        $<$<BOOL:${PLATFORM_DEFAULT_ATTEST_HAL}>:ext/common/template/attest_hal.c>
        $<$<BOOL:${PLATFORM_DEFAULT_NV_COUNTERS}>:ext/common/template/nv_counters.c>
        $<$<AND:$<BOOL:${TFM_PARTITION_CRYPTO}>,$<BOOL:${PLATFORM_DEFAULT_CRYPTO_KEYS}>>:ext/common/template/crypto_keys.c>
        $<$<BOOL:${PLATFORM_DEFAULT_ROTPK}>:ext/common/template/tfm_rotpk.c>
        $<$<BOOL:${PLATFORM_DEFAULT_NV_SEED}>:ext/common/template/crypto_nv_seed.c>
        $<$<AND:$<NOT:$<BOOL:${ATTEST_TEST_GET_PUBLIC_KEY}>>,$<NOT:$<BOOL:${SYMMETRIC_INITIAL_ATTESTATION}>>,$<BOOL:${TEST_S_ATTESTATION}>>:ext/common/template/tfm_initial_attest_pub_key.c>
        $<$<OR:$<BOOL:${PLATFORM_DEFAULT_NV_COUNTERS}>,$<BOOL:${PLATFORM_DEFAULT_OTP}>>:ext/common/template/flash_otp_nv_counters_backend.c>
        $<$<BOOL:${PLATFORM_DEFAULT_OTP}>:ext/common/template/otp_flash.c>
        $<$<BOOL:${PLATFORM_DEFAULT_PROVISIONING}>:ext/common/provisioning.c>
)

target_sources(tfm_s
    PRIVATE
        ext/common/faults.c
)

target_link_libraries(platform_s
    PUBLIC
        platform_common_interface
        platform_region_defs
        tfm_fih
    PRIVATE
        psa_interface
        tfm_secure_api
        tfm_arch
        tfm_partition_defs
        $<$<BOOL:${PLATFORM_DEFAULT_ATTEST_HAL}>:tfm_sprt>
        $<$<BOOL:${TFM_PARTITION_CRYPTO}>:crypto_service_mbedcrypto>
)

target_compile_definitions(platform_s
    PUBLIC
        TFM_SPM_LOG_LEVEL=${TFM_SPM_LOG_LEVEL}
        $<$<BOOL:${TFM_SPM_LOG_RAW_ENABLED}>:TFM_SPM_LOG_RAW_ENABLED>
        $<$<BOOL:${OTP_NV_COUNTERS_RAM_EMULATION}>:OTP_NV_COUNTERS_RAM_EMULATION>
        $<$<BOOL:${TFM_EXCEPTION_INFO_DUMP}>:TFM_EXCEPTION_INFO_DUMP>
        CONFIG_TFM_SPE_FP=${CONFIG_TFM_SPE_FP}
        $<$<BOOL:${CONFIG_TFM_LAZY_STACKING_SPE}>:CONFIG_TFM_LAZY_STACKING_SPE>
    PRIVATE
        $<$<BOOL:${SYMMETRIC_INITIAL_ATTESTATION}>:SYMMETRIC_INITIAL_ATTESTATION>
        $<$<OR:$<VERSION_GREATER:${TFM_ISOLATION_LEVEL},1>,$<STREQUAL:"${TEST_PSA_API}","IPC">>:CONFIG_TFM_ENABLE_MEMORY_PROTECT>
        $<$<AND:$<BOOL:${TFM_PXN_ENABLE}>,$<STREQUAL:${TFM_SYSTEM_ARCHITECTURE},armv8.1-m.main>>:TFM_PXN_ENABLE>
        $<$<BOOL:${PLATFORM_DEFAULT_OTP}>:PLATFORM_DEFAULT_OTP>
        $<$<BOOL:${TFM_DUMMY_PROVISIONING}>:TFM_DUMMY_PROVISIONING>
        $<$<BOOL:${ATTEST_INCLUDE_COSE_KEY_ID}>:ATTEST_INCLUDE_COSE_KEY_ID>
        $<$<BOOL:${PLATFORM_DEFAULT_NV_COUNTERS}>:PLATFORM_DEFAULT_NV_COUNTERS>
        $<$<BOOL:${PLATFORM_DEFAULT_OTP}>:PLATFORM_DEFAULT_OTP>
        $<$<BOOL:${PLATFORM_DEFAULT_OTP_WRITEABLE}>:OTP_WRITEABLE>
)

target_compile_options(platform_s
    PUBLIC
        ${COMPILER_CP_FLAG}
)

#========================= Platform Non-Secure ================================#

target_sources(platform_ns
    PRIVATE
        $<$<BOOL:${PLATFORM_DEFAULT_UART_STDOUT}>:${CMAKE_CURRENT_SOURCE_DIR}/ext/common/uart_stdout.c>
        $<$<AND:$<NOT:$<BOOL:${ATTEST_TEST_GET_PUBLIC_KEY}>>,$<NOT:$<BOOL:${SYMMETRIC_INITIAL_ATTESTATION}>>,$<BOOL:${TEST_NS_ATTESTATION}>>:${CMAKE_CURRENT_SOURCE_DIR}/ext/common/template/tfm_initial_attest_pub_key.c>
)

target_link_libraries(platform_ns
    PUBLIC
        platform_common_interface
        platform_region_defs
        tfm_ns_interface
)

target_compile_definitions(platform_ns
    PRIVATE
        $<$<BOOL:${TEST_NS_SLIH_IRQ}>:TEST_NS_SLIH_IRQ>
)

#========================= Platform BL2 =======================================#
if(BL2)
    #TODO import policy
    target_include_directories(platform_bl2
        PUBLIC
            $<$<BOOL:${CRYPTO_HW_ACCELERATOR}>:${CMAKE_CURRENT_SOURCE_DIR}/ext/accelerator/interface>
    )

    target_sources(platform_bl2
        PRIVATE
            ext/common/boot_hal.c
            $<$<BOOL:${PLATFORM_DEFAULT_UART_STDOUT}>:${CMAKE_CURRENT_SOURCE_DIR}/ext/common/uart_stdout.c>
            $<$<BOOL:${PLATFORM_DEFAULT_NV_COUNTERS}>:ext/common/template/nv_counters.c>
            $<$<BOOL:${PLATFORM_DEFAULT_ROTPK}>:ext/common/template/tfm_rotpk.c>
            $<$<OR:$<BOOL:${PLATFORM_DEFAULT_NV_COUNTERS}>,$<BOOL:${PLATFORM_DEFAULT_OTP}>>:ext/common/template/flash_otp_nv_counters_backend.c>
            $<$<BOOL:${PLATFORM_DEFAULT_OTP}>:ext/common/template/otp_flash.c>
    )

    target_link_libraries(platform_bl2
        PUBLIC
            platform_common_interface
            platform_region_defs
        PRIVATE
            psa_interface
            bl2_hal
            tfm_arch
    )

    target_compile_definitions(platform_bl2
        PUBLIC
            BL2
            MCUBOOT_${MCUBOOT_UPGRADE_STRATEGY}
            $<$<BOOL:${MCUBOOT_DIRECT_XIP_REVERT}>:MCUBOOT_DIRECT_XIP_REVERT>
            $<$<BOOL:${SYMMETRIC_INITIAL_ATTESTATION}>:SYMMETRIC_INITIAL_ATTESTATION>
            $<$<BOOL:${MCUBOOT_HW_KEY}>:MCUBOOT_HW_KEY>
            MCUBOOT_FIH_PROFILE_${MCUBOOT_FIH_PROFILE}
            $<$<BOOL:${PLATFORM_DEFAULT_OTP}>:PLATFORM_DEFAULT_OTP>
            $<$<BOOL:${OTP_NV_COUNTERS_RAM_EMULATION}>:OTP_NV_COUNTERS_RAM_EMULATION>
            $<$<BOOL:${TFM_DUMMY_PROVISIONING}>:TFM_DUMMY_PROVISIONING>
            $<$<BOOL:${ATTEST_INCLUDE_COSE_KEY_ID}>:ATTEST_INCLUDE_COSE_KEY_ID>
            $<$<BOOL:${PLATFORM_DEFAULT_NV_COUNTERS}>:PLATFORM_DEFAULT_NV_COUNTERS>
            $<$<BOOL:${PLATFORM_DEFAULT_OTP_WRITEABLE}>:OTP_WRITEABLE>
        )
endif()

#========================= Platform region defs ===============================#

#TODO maybe just link the other platforms to this
target_compile_definitions(platform_region_defs
    INTERFACE
        $<$<BOOL:${BL1}>:BL1>
        $<$<BOOL:${BL2}>:BL2>
        BL2_HEADER_SIZE=${BL2_HEADER_SIZE}
        BL2_TRAILER_SIZE=${BL2_TRAILER_SIZE}
        $<$<BOOL:${SECURE_UART1}>:SECURE_UART1>
        DAUTH_${DEBUG_AUTHENTICATION}
        $<$<BOOL:${MCUBOOT_IMAGE_NUMBER}>:MCUBOOT_IMAGE_NUMBER=${MCUBOOT_IMAGE_NUMBER}>
        $<$<STREQUAL:${MCUBOOT_SIGNATURE_TYPE},RSA>:MCUBOOT_SIGN_RSA>
        $<$<STREQUAL:${MCUBOOT_SIGNATURE_TYPE},RSA>:MCUBOOT_SIGN_RSA_LEN=${MCUBOOT_SIGNATURE_KEY_LEN}>
        $<$<STREQUAL:${MCUBOOT_EXECUTION_SLOT},2>:LINK_TO_SECONDARY_PARTITION>
        $<$<BOOL:${TEST_PSA_API}>:PSA_API_TEST_${TEST_PSA_API}>
        $<$<BOOL:${FORWARD_PROT_MSG}>:FORWARD_PROT_MSG=${FORWARD_PROT_MSG}>
        $<$<BOOL:${TFM_CODE_SHARING}>:CODE_SHARING>
)
