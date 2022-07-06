<div align="center">
  <img src="https://www.quadrans.io/assets/brand/logo_quadrans_color.svg"><br>
</div>

-----------------

## Quadrans Bash Installer (and Batch Installer)

`gqdc-installer.sh` is a command line tools that allows to install the **Go Quadrans node binary** for **Linux** (x86, x86-64, armv7, arm64) and **macOS** (x86-64).

`gqdc-winstaller.bat` is a command line tools that allows to create a **Launcher** for the **Go Quadrans node binary** for **Windows** (x86-64).

With `gqdc-installer.sh` you can:
1. **Install** Quadrans node (on Mainnet or Testnet)
2. **Update** existing node
3. **Uninstall** Quadrans node
4. **Reconfigure** node (recover a previous uninstalled Quadrans node)
5. **Change** Quadrans node Network (switch between Mainnet and Testnet)

With `gqdc-winstaller.bat` you can:
1. **Install** Quadrans node
2. **Configure** a Quadrans node wallet
3. **Create** a Launcher file to execute your node

## Usage

**On Linux:**

Open a Terminal or Console and execute:

```bash
wget http://repo.quadrans.io/installer/gqdc-installer.sh
sudo bash gqdc-installer.sh
```

**On Mac:**

Open a Terminal or Console and execute:

```bash
curl -s http://repo.quadrans.io/installer/gqdc-installer.sh > gqdc-installer.sh
sudo bash gqdc-installer.sh
```

**On Windows:**

Open a Command Prompt and execute:

```bash
curl -s https://repo.quadrans.io/installer/gqdc-winstaller.bat -o gqdc-winstaller.bat
gqdc-winstaller.bat
```

or open a PowerShell and execute:

```bash
Invoke-WebRequest -Uri https://repo.quadrans.io/installer/gqdc-winstaller.bat -OutFile gqdc-installer.bat 
.\gqdc-winstaller.bat
```

Follow the on screen instructions.

## License
[GNU GPL 3](LICENSE)

## Links
* [Quadrans Blockchain website](https://quadrans.io)
* [Quadrans Documentation](https://docs.quadrans.io)