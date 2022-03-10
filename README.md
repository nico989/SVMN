# Softwarized and Virtualized Mobile Networks | Morphing Slices

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

### Distribution

Generate `morphing_slices.tar.gz`:

```bash
scripts/prod.sh
```

## Production

### Installation

> All commands must be executed inside `comnetsemu`

1. Download `morphing_slices.tar.gz` from GitHub release:

   ```bash
   wget https://github.com/nico989/SVMN/releases/latest/download/morphing_slices.tar.gz
   ```

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

1. Scripts permissions:

   ```bash
   chmod -R +x scripts
   ```

1. Initialize:

   ```bash
   sudo scripts/init.sh
   ```

## Clean

Ensure to clean old works in `comnetsemu`.

> All commands must be executed inside `comnetsemu`

```bash
scripts/clean.sh
```

## Scenario 1

![Scenario 1](assets/scenario_1.png)

TODO Aggiungere descrizione scenario 1

### Terminal 1

1. Create network topology:

   ```bash
   sudo python3 topology.py --file scenarios/1/topology.yaml
   ```

1. Wait `Terminal 2.2`.

1. Wait `Terminal 3.1`

1. Increment the counter:

   > Make as many requests as you want

   ```bash
   c0 curl -X POST 192.168.0.100/api/counter
   ```

### Terminal 2

1. Start FlowVisor container:

   ```bash
   scripts/flowvisor.sh --volume scenarios/1
   ```

1. Run FlowVisor:

   ```bash
   ./flowvisor.sh
   ```

1. Wait `Terminal 3.1`.

1. Migrate:

   > Press `Enter`

   > Make as many migrations as you want

   ```bash
   Press 'Enter' to migrate or 'q' to exit
   ```

### Terminal 3

1. Start Ryu controller(s):

   ```bash
   parallel --ungroup ::: 'scripts/ryu.sh --controller scenarios/1/controller.py --ofport 10001 --port 8082 --config scenarios/1/controller.cfg' 'scripts/ryu.sh --controller scenarios/1/controller.py --ofport 10002 --port 8083'
   ```

1. Open browser at <http://localhost:8082>

1. Open browser at <http://localhost:8083>

## Scenario 2

![Scenario 2](assets/scenario_2.png)

TODO Aggiungere descrizione scenario 2

### Terminal 1

1. Create network topology:

   ```bash
   sudo python3 topology.py --file scenarios/2/topology.yaml
   ```

1. Wait `Terminal 2.1`.

1. Increment the counter:

   > Make as many requests as you want

   ```bash
   c0 curl -X POST 192.168.0.100/api/counter
   ```

### Terminal 2

1. Run OpenFlow:

   ```bash
   scenarios/2/openflow.sh
   ```

1. Migrate:

   > Press `Enter`

   > Make as many migrations as you want

   ```bash
   Press 'Enter' to migrate or 'q' to exit
   ```

## License

This project is licensed under the MIT License.
See [LICENSE](LICENSE) file for details.
