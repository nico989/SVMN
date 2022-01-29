# Softwarized and Virtualized Mobile Networks

## Members

|  Name  |  Surname  |     Username     |    MAT     |
| :----: | :-------: | :--------------: | :--------: |
| Carlo  | Corradini | `carlocorradini` | **223811** |
| Nicolò |   Vinci   |    `nico989`     | **220229** |
| Mattia | Perpenti  |    `MrPerpe`     | **229371** |

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Clone

```bash
$ git clone --recursive https://github.com/nico989/SVMN.git
$ cd SVMN
```

### Permissions

```bash
$ chmod -R +x scripts
```

### Initialize

#### Linux | MacOS

```bash
$ scripts/init.sh
```

#### Windows

`Windows` users must install [`WSL` (Windows Subsystem for Linux)](https://docs.microsoft.com/windows/wsl/install).<br/>
To correctly configure the project in `WSL` you must follow these steps:

> Configuration must be done in `WSL` and not in `Windows`.

1. Install [`Vagrant`](https://www.vagrantup.com/downloads) in `WSL`.<br/>
   Note that you must also have installed `Vagrant` in `Windows`.

2. Configure `Vagrant` to run in `WSL` following the official guide [_Vagrant and Windows Subsystem for Linux_](https://www.vagrantup.com/docs/other/wsl).

3. Install [`virtualbox_WSL2`](https://github.com/Karandash8/virtualbox_WSL2) `Vagrant` plugin in `WSL`:

   ```bash
   $ vagrant plugin install virtualbox_WSL2
   ```

4. Replace line _565_ of `platform.rb` file located at `/opt/vagrant/embedded/gems/[VAGRANT_VERSION]/gems/vagrant-[VAGRANT_VERSION]/lib/vagrant/util/platform.rb` from:

   ```ruby
   if info && (info[:type] == "drvfs" || info[:type] == "9p")
   ```

   To

   ```ruby
   if info && (info[:type] == "drvfs" || info[:type] == "9p" || info[:type] == "ext4")
   ```

   See [this issue](https://github.com/hashicorp/vagrant/issues/11623) for more information.

5. Run the initialization script:
   ```bash
   $ scripts/init.sh
   ```

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.
