PKG_INSTALL:=1

ifneq ($(findstring c,$(OPENWRT_VERBOSE)),)
  MAKE_FLAGS+=VERBOSE=1
endif

CMAKE_SOURCE_DIR:=.

ifeq ($(CONFIG_EXTERNAL_TOOLCHAIN),)
  cmake_tool=$(TOOLCHAIN_DIR)/bin/$(1)
else
  cmake_tool=$(shell which $(1))
endif

ifeq ($(CONFIG_CCACHE),)
 CMAKE_C_COMPILER:=$(call cmake_tool,$(TARGET_CC))
 CMAKE_CXX_COMPILER:=$(call cmake_tool,$(TARGET_CXX))
 CMAKE_C_COMPILER_ARG1:=
 CMAKE_CXX_COMPILER_ARG1:=
else
  CCACHE:=$(shell which ccache)
  ifeq ($(CCACHE),)
    CCACHE:=$(STAGING_DIR_HOST)/bin/ccache
  endif
  CMAKE_C_COMPILER:=$(CCACHE)
  CMAKE_C_COMPILER_ARG1:=$(TARGET_CC_NOCACHE)
  CMAKE_CXX_COMPILER:=$(CCACHE)
  CMAKE_CXX_COMPILER_ARG1:=$(TARGET_CXX_NOCACHE)
endif
CMAKE_AR:=$(call cmake_tool,$(TARGET_AR))
CMAKE_NM:=$(call cmake_tool,$(TARGET_NM))
CMAKE_RANLIB:=$(call cmake_tool,$(TARGET_RANLIB))

CMAKE_FIND_ROOT_PATH:=$(STAGING_DIR);$(TOOLCHAIN_DIR)$(if $(CONFIG_EXTERNAL_TOOLCHAIN),;$(CONFIG_TOOLCHAIN_ROOT))

define Build/Configure/Default
	(cd $(PKG_BUILD_DIR); \
		CFLAGS="$(TARGET_CFLAGS) $(EXTRA_CFLAGS)" \
		CXXFLAGS="$(TARGET_CFLAGS) $(EXTRA_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS) $(EXTRA_LDFLAGS)" \
		cmake \
			-DCMAKE_SYSTEM_NAME=Linux \
			-DCMAKE_SYSTEM_VERSION=1 \
			-DCMAKE_SYSTEM_PROCESSOR=$(ARCH) \
			-DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_C_FLAGS_RELEASE="-DNDEBUG" \
			-DCMAKE_CXX_FLAGS_RELEASE="-DNDEBUG" \
			-DCMAKE_C_COMPILER="$(CMAKE_C_COMPILER)" \
			-DCMAKE_C_COMPILER_ARG1="$(CMAKE_C_COMPILER_ARG1)" \
			-DCMAKE_CXX_COMPILER="$(CMAKE_CXX_COMPILER)" \
			-DCMAKE_CXX_COMPILER_ARG1="$(CMAKE_CXX_COMPILER_ARG1)" \
			-DCMAKE_EXE_LINKER_FLAGS:STRING="$(TARGET_LDFLAGS)" \
			-DCMAKE_MODULE_LINKER_FLAGS:STRING="$(TARGET_LDFLAGS)" \
			-DCMAKE_SHARED_LINKER_FLAGS:STRING="$(TARGET_LDFLAGS)" \
			-DCMAKE_AR="$(CMAKE_AR)" \
			-DCMAKE_NM="$(CMAKE_NM)" \
			-DCMAKE_RANLIB="$(CMAKE_RANLIB)" \
			-DCMAKE_FIND_ROOT_PATH="$(CMAKE_FIND_ROOT_PATH)" \
			-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=BOTH \
			-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
			-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
			-DCMAKE_STRIP=: \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DDL_LIBRARY=$(STAGING_DIR) \
			-DCMAKE_PREFIX_PATH=$(STAGING_DIR) \
			-DCMAKE_SKIP_RPATH=TRUE  \
			$(CMAKE_OPTIONS) \
		$(CMAKE_SOURCE_DIR) \
	)
endef

define Build/InstallDev/cmake
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_INSTALL_DIR)/* $(1)/
endef

Build/InstallDev = $(if $(CMAKE_INSTALL),$(Build/InstallDev/cmake))
