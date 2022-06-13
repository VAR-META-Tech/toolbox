include(FeatureSummary)
include(FindLinuxPlatform)
include(CMakePackageConfigHelpers)

set(INSTALL_BIN_DIR bin)
set(INSTALL_LIB_DIR lib/${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR})
set(INSTALL_CMAKE_DIR ${INSTALL_LIB_DIR}/cmake)
set(INSTALL_INCLUDE_DIR include)

set(target_deps "")

if (Boost_FOUND)
	if (WIN32)
		list(APPEND target_deps "find_dependency(Boost REQUIRED)")
	else ()
		list(APPEND target_deps "find_dependency(Boost COMPONENTS regex REQUIRED)")
	endif ()
endif ()
if (target_deps)
	list(JOIN target_deps "\n" targets_deps_joined)
	set(HAS_TARGET_DEPS 1)
endif ()

configure_package_config_file(
	${CMAKE_CURRENT_SOURCE_DIR}/cfg/${PROJECT_NAME}-config.cmake.in
	${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
	INSTALL_DESTINATION lib/${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}/cmake
	PATH_VARS INSTALL_LIB_DIR INSTALL_INCLUDE_DIR INSTALL_CMAKE_DIR
)

write_basic_package_version_file(
	${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
	VERSION ${PROJECT_VERSION}
	COMPATIBILITY SameMajorVersion)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cfg/toolbox.pc.in ${CMAKE_CURRENT_BINARY_DIR}/pkgconfig/toolbox.pc @ONLY)

install(
	FILES
	${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
	${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
	DESTINATION ${INSTALL_CMAKE_DIR}
)

install(
	TARGETS ${PROJECT_NAME}
	EXPORT ${PROJECT_NAME}-targets
	RUNTIME DESTINATION ${INSTALL_BIN_DIR}
	LIBRARY DESTINATION ${INSTALL_LIB_DIR}
	ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
	PUBLIC_HEADER DESTINATION ${INSTALL_INCLUDE_DIR}
)

install(
	DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/toolbox
	DESTINATION ${INSTALL_INCLUDE_DIR}
)

install(
	DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/pkgconfig
	DESTINATION lib/pkgconfig
)

install(EXPORT ${PROJECT_NAME}-targets
        NAMESPACE ${PROJECT_NAME}::
        FILE "${PROJECT_NAME}-targets.cmake"
        DESTINATION ${INSTALL_CMAKE_DIR}
        )

set(PACKAGE_RELEASE 3)
set(CPACK_PACKAGE_NAME toolboxpp)
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_VENDOR "Eduard Maximovich")
set(CPACK_PACKAGE_CONTACT "edward.vstock@gmail.com")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/edwardstock/toolbox")
set(CPACK_PACKAGE_VCS_URL "https://github.com/edwardstock/toolbox.git")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${PROJECT_DESCRIPTION})
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
	if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 6.0.0)
		message(STATUS "Add Boost.Regex dependency to package")
		if (IS_REDHAT)
			set(CPACK_RPM_PACKAGE_REQUIRES "boost-devel >= 1.50.0")
		elseif (IS_DEBIAN)
			set(CPACK_DEBIAN_PACKAGE_DEPENDS "libboost-regex-dev (>= 1.50.0)")
		endif ()
	endif ()
endif ()

if ((IS_REDHAT OR IS_DEBIAN) AND NOT PACKAGE_ARCHIVE)
	if (IS_REDHAT)
		message(STATUS "Build package for redhat ${RH_MAJOR_VERSION}")

		get_target_property(target_type ${PROJECT_NAME} TYPE)
		if (target_type STREQUAL "EXECUTABLE")
			set(PACKAGE_NAME "${CPACK_PACKAGE_NAME}")
		else ()
			set(PACKAGE_NAME "${CPACK_PACKAGE_NAME}-devel")
		endif ()

		set(PACKAGE_EXT ".rpm")
		set(CPACK_GENERATOR "RPM")
		set(CPACK_RPM_PACKAGE_NAME ${PACKAGE_NAME})
		set(CPACK_RPM_PACKAGE_ARCHITECTURE "${PROJECT_ARCH}")
		set(CPACK_RPM_PACKAGE_RELEASE "${PACKAGE_RELEASE}.${RH_MAJOR_NAME}")
		set(CPACK_RPM_PACKAGE_LICENSE "MIT")
		set(CPACK_RPM_PACKAGE_URL ${CPACK_PACKAGE_HOMEPAGE_URL})
		set(CPACK_RPM_PACKAGE_GROUP "Development/Libraries")

		# out file name
		set(CPACK_PACKAGE_FILE_NAME "${CPACK_RPM_PACKAGE_NAME}-${CMAKE_PROJECT_VERSION}-${CPACK_RPM_PACKAGE_RELEASE}.${CMAKE_SYSTEM_PROCESSOR}")

		# upload vars
		set(JFROG_OPTIONS "--url=$ARTIFACTORY_RHEL_URL --apikey=$ARTIFACTORY_API_KEY")
		set(URL_SUFFIX "")
		set(REPO_NAME rh)
		set(TARGET_PATH "${OS_NAME}/${RH_MAJOR_VERSION}/${CMAKE_SYSTEM_PROCESSOR}/")
		set(UPLOAD_FILE_NAME ${CPACK_PACKAGE_FILE_NAME}.rpm)
		configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cfg/package_upload.sh ${CMAKE_CURRENT_BINARY_DIR}/package_upload.sh @ONLY)
	else ()
		get_target_property(target_type ${PROJECT_NAME} TYPE)
		if (target_type STREQUAL "EXECUTABLE")
			set(PACKAGE_NAME "${CPACK_PACKAGE_NAME}")
		else ()
			set(PACKAGE_NAME "lib${CPACK_PACKAGE_NAME}-dev")
		endif ()

		set(PACKAGE_EXT "")
		set(CPACK_GENERATOR "DEB")
		set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Eduard Maximovich <edward.vstock@gmail.com>")
		set(CPACK_DEBIAN_PACKAGE_RELEASE ${PACKAGE_RELEASE})
		set(CPACK_DEBIAN_PACKAGE_NAME "${PACKAGE_NAME}")
		set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${PROJECT_ARCH})
		set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
		set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
		set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "${CPACK_PACKAGE_HOMEPAGE_URL}")
		set(CPACK_DEBIAN_FILE_NAME "${CPACK_DEBIAN_PACKAGE_NAME}_${PROJECT_VERSION}-${PACKAGE_RELEASE}_${OS_ARCH}.deb")

		# upload vars
		set(JFROG_OPTIONS "--deb \"${DEB_DIST_NAME}/main/${OS_ARCH}\" --url=$ARTIFACTORY_DEB_URL --apikey=$ARTIFACTORY_API_KEY")
		set(REPO_NAME ${OS_NAME})
		set(TARGET_PATH "dists/${DEB_DIST_NAME}/main/")
		set(UPLOAD_FILE_NAME ${CPACK_DEBIAN_FILE_NAME})
		configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cfg/package_upload.sh ${CMAKE_CURRENT_BINARY_DIR}/package_upload.sh @ONLY)
	endif ()

else ()
	set(PACKAGE_EXT ".sh")
	set(CPACK_GENERATOR "STGZ")
	set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
	set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CMAKE_PROJECT_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
	set(UPLOAD_FILE_NAME ${CPACK_PACKAGE_FILE_NAME}.sh)
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cfg/package_upload.sh ${CMAKE_CURRENT_BINARY_DIR}/package_upload.sh @ONLY)
endif ()
include(CPack)
