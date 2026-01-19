# zlib-pkg-builder

This project will build, bundle and deploy ZLIB as a package, to be used by the Mimi Engine.

# Build steps

preset = { macos-arm64-Release, macos-arm64-Debug }

1. Setup (submodules, node modules, ...etc.).
```
./run.sh setup
```

2. Build
```
./run.sh build <preset>
```

2. Bundle built project to be deployed.
```
./run.sh bundle <preset>
```

3. Deploy bundle to S3.
```
./run.sh deploy <preset>
```

S3 uploads are configured through **.env** variables.
```
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=...
AWS_S3_BUCKET=...
AWS_S3_UPLOAD_ROOT=...
```

## Other Key Files

### manifest.json
A configuration file that defines how the subproject should be built for various target platforms and configurations. This file is used as an input into prebuild-utils, to configure the build environment (eg. stdlib, rtti, exceptions, ....etc) and towards generating the build's ABI fingerprint for bundling / deployment.

### CMakeLists.txt
CMake build script that configures the build environment, detects the current ABI, reads options from `manifest.json`, and sets up the build for our subproject. This file ensures consistent build settings and proper output directories for prebuilt binaries.
See [CMake documentation](https://cmake.org/cmake/help/latest/index.html) for more details.

### CMakePresets.json
CMake presets are configuration files (CMakePresets.json and optionally CMakeUserPresets.json) that define a set of named build and test configurations for CMake. 
See [CMake documentation on presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html) for more details.
