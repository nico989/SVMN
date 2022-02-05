# Softwarized and Virtualized Mobile Networks

[![CI](https://github.com/nico989/SVMN/workflows/ci/badge.svg)](https://github.com/nico989/SVMN/actions)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

## Members

|  Name  |  Surname  |     Username     |    MAT     |
| :----: | :-------: | :--------------: | :--------: |
| Carlo  | Corradini | `carlocorradini` | **223811** |
| Nicolò |   Vinci   |    `nico989`     | **220229** |
| Mattia | Perpenti  |    `MrPerpe`     | **229371** |

## Getting Started

These instructions will get you a copy of the project up and running on your
local machine for development and testing purposes.

### Clone

```bash
git clone --recursive https://github.com/nico989/SVMN.git
cd SVMN
```

### Permissions

```bash
chmod -R +x scripts
```

### Initialize

#### Linux

Run the initialization script:

```bash
scripts/init.sh
```

#### Windows

`Windows` users must install [`WSL` (Windows Subsystem for Linux)](https://docs.microsoft.com/windows/wsl/install).\
To correctly configure the project in `WSL` you must follow these steps:

> Configuration must be done in `WSL` and not in `Windows`.

1. Install [`Vagrant`](https://www.vagrantup.com/downloads) in `WSL`.\
   Note that you must also have installed `Vagrant` in `Windows`.
1. Configure `Vagrant` to run in `WSL` following the official guide
   [_Vagrant and Windows Subsystem for Linux_](https://www.vagrantup.com/docs/other/wsl).
1. Install [`virtualbox_WSL2`](https://github.com/Karandash8/virtualbox_WSL2)
   `Vagrant` plugin in `WSL`:

   ```bash
   vagrant plugin install virtualbox_WSL2
   ```

1. Replace line _565_ of `platform.rb` file located at
   `/opt/vagrant/embedded/gems/[VAGRANT_VERSION]/gems/vagrant-[VAGRANT_VERSION]/lib/vagrant/util/platform.rb`
   from:

   ```ruby
   if info && (info[:type] == "drvfs" || info[:type] == "9p")
   ```

   To

   ```ruby
   if info && (info[:type] == "drvfs" || info[:type] == "9p" || info[:type] == "ext4")
   ```

   See [this issue](https://github.com/hashicorp/vagrant/issues/11623) for more information.

1. Run the initialization script:

   ```bash
   scripts/init.sh
   ```

## Development

> Prepare `comnetsemu` and keeps updated working directory

```bash
scripts/dev.sh
```

## Production

### Distribution

Generate `morphing_slices.tar.gz` file:

```bash
scripts/prod.sh
```

### Installation

> All commands must be executed inside `comnetsemu`

1. Create `morphing_slices` directory:

   ```bash
   mkdir morphing_slices
   ```

1. Extract `morphing_slices.tar.gz` into `morphing_slices` directory:

   ```bash
   tar -xzf morphing_slices.tar.gz -D morphing_slices
   ```

1. Change working directory to `morphing_slices`:

   ```bash
   cd morphing_slices
   ```

1. Install Python dependencies:

   ```bash
   sudo pip install -r requirements.txt
   ```

## Clean

Ensure to clean old works in `comnetsemu`.

> All commands must be executed inside `comnetsemu`

```bash
scripts/clean.sh
```

## Scenario 1

> All commands must be executed inside `comnetsemu`

### Terminal 1

1. Create network topology:

   ```bash
   sudo python3 topology.py -f topology.yaml
   ```

### Terminal 2

### Terminal 3

## License

This project is licensed under the MIT License.
See [LICENSE](LICENSE) file for details.
