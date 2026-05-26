# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0](https://github.com/Segfault-Git/Simple-Explorer-Menu/compare/v0.0.1...v1.0.0) (2026-05-26)

### ⚠ BREAKING CHANGES

* unify into single sem.ps1 with one-liner support

### Features

* add dev branch CI with pre-release and semReleaseTag ([1c65a93](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/1c65a9325f374056a415abc9dcc80e9780ff0410))
* unify into single sem.ps1 with one-liner support ([83eff36](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/83eff36c04814e4a3cab64da56a3dcd7acff169d))
* wrap in function menu for irm | iex; menu pattern ([2b47c72](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/2b47c72fdbadbed8a5e0a93d1fb0bec820723fcb))

### Bug Fixes

* add critical data validation after Install-SEMData ([e9a9f36](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/e9a9f36d00e3b57f5f11a0d587694f779a9bc612))
* clear DarkGray background remnants in menu navigation ([41fad08](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/41fad0831c89cbb4e992b7bb81edc6482c58009a))
* improve Install-SEMData and remove duplicate admin check ([ff9c860](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/ff9c8604b0f4db540dc0f2813da69972e0fa6b57))
* match SEM.zip exactly to avoid matching sem.ps1 ([3f2e420](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/3f2e4207d455dce49d5735252a2a73f87b02b7be))
* move Clear-Host after Install-SEMData to prevent console buffer scroll garbage ([78897bc](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/78897bc0be688252cbe24e327f3044414c730ecd))
* reduce itemsPerPage to 15, compact footer to fit console window ([fddac63](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/fddac634833da6aa0b755d8677490a67b6217091))
* remove script-level param() to fix irm | iex crash ([69bc78b](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/69bc78b793030864e5c6aabf9efe8aa85f023d0e))
* remove ValidatePattern on  to allow empty default (irm | iex crash) ([ac87b75](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/ac87b7576cf0ae96797865b631a3a1f51e948e43))
* restore 2-line footer ([cc8fbb4](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/cc8fbb47f9ee0eb58250aa6a650b437409ad2c03))
* use temp .ps1 file for elevation when run via irm | iex ([be79c60](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/be79c602ef0debd389bd0bcebd95c1bccebc7bc9))

## [0.0.1](https://github.com/Segfault-Git/Simple-Explorer-Menu/compare/v0.0.0...v0.0.1) (2025-12-02)

### Bug Fixes

* trigger patch release ([b67e2f0](https://github.com/Segfault-Git/Simple-Explorer-Menu/commit/b67e2f094c67e8cca06b3d988efe327d62353d04))
