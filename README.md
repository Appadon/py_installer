# Python Universal Installer

A robust bash script for installing Python from source on multiple Linux distributions.
This installer provides an interactive version selection interface, automatic dependency management, and optimized compilation settings.

## Features

- **Multi-Distribution Support**: Works across Debian, Ubuntu, Arch, Fedora, CentOS, RHEL, and derivative distributions
- **Interactive Version Selection**: Fetches and displays the latest Python versions from python.org
- **Version Verification**: Validates tarball availability before attempting installation
- **Automatic Dependency Installation**: Detects distribution and installs required build dependencies
- **Optimized Compilation**: Enables Python optimizations and uses all available CPU cores
- **Safe Installation**: Uses `altinstall` to avoid overwriting system Python
- **Shared Library Support**: Builds Python with shared library support for better integration
- **Virtual Environment Ready**: Automatically installs and configures pip and virtualenv
- **System Integration**: Updates library cache and shell configurations automatically
- **Comprehensive Error Handling**: Detailed error messages with actionable suggestions
- **Color-Coded Output**: Clear visual feedback for success, errors, warnings, and info messages

## Supported Distributions

### Debian-based
- Ubuntu
- Debian
- Linux Mint
- Pop!_OS

### Arch-based
- Arch Linux
- Manjaro
- EndeavourOS

### Red Hat-based
- Fedora
- CentOS
- RHEL
- Rocky Linux
- AlmaLinux

## Prerequisites

- Root or sudo access
- Internet connection
- `curl` (for version fetching)
- `wget` (for downloading Python)

## Installation

### Download the Script

```bash
wget https://raw.githubusercontent.com/yourusername/yourrepo/main/install_python_universal.sh
chmod +x install_python_universal.sh
```

### Run the Script

```bash
sudo ./install_python_universal.sh
```

## Usage

### Interactive Mode

The script runs in interactive mode by default:

1. Fetches available Python versions from python.org
2. Displays the latest 10 versions for selection
3. Verifies the selected version is available
4. Detects your Linux distribution
5. Prompts for confirmation before installation
6. Installs dependencies, downloads, compiles, and configures Python

### Default Version

To set a default Python version, modify the `PYTHON_VERSION` variable in the script before running:

```bash
PYTHON_VERSION="3.12.0"
```

### Custom Installation Directory

To change the installation directory, modify the `INSTALL_DIR` variable:

```bash
INSTALL_DIR="/opt/python"
```

## Installation Process

The installer performs the following steps:

1. **Version Selection**: Presents available Python versions or uses default
2. **Version Verification**: Validates that the tarball exists and is downloadable
3. **Distribution Detection**: Identifies your Linux distribution
4. **Dependency Installation**: Installs all required development tools and libraries
5. **Download**: Downloads Python source tarball with progress indication
6. **Extraction**: Extracts and verifies the downloaded archive
7. **Configuration**: Configures Python with optimizations enabled
8. **Compilation**: Compiles Python using all available CPU cores (10-20 minutes)
9. **Installation**: Performs altinstall to avoid conflicts with system Python
10. **pip Setup**: Upgrades pip and installs virtualenv
11. **System Configuration**: Updates library cache and shell configurations
12. **Cleanup**: Removes temporary files
13. **Summary**: Displays installation details and quick start commands

## After Installation

### Verify Installation

```bash
python3.12 --version
pip3.12 --version
```

### Create Virtual Environment

```bash
python3.12 -m venv myproject
source myproject/bin/activate
```

### Update Shell Environment

Restart your terminal or source your shell configuration:

```bash
source ~/.bashrc
```

## Installation Paths

- **Python Binary**: `/usr/local/bin/python3.X`
- **pip Binary**: `/usr/local/bin/pip3.X`
- **Libraries**: `/usr/local/lib/python3.X`
- **Include Files**: `/usr/local/include/python3.X`

## Compilation Options

The script compiles Python with the following configuration options:

- `--enable-optimizations`: Enables profile-guided optimizations for better performance
- `--with-ensurepip=install`: Ensures pip is installed automatically
- `--enable-shared`: Builds shared Python library for better integration
- `LDFLAGS="-Wl,-rpath /usr/local/lib"`: Sets runtime library path

## Troubleshooting

### Version Not Available

If a version shows in the list but fails verification:

- The version may be announced but not yet officially released
- Try selecting a different version from the list
- Check python.org/downloads for release status

### Download Failures

If downloads fail:

- Check your internet connection
- Verify firewall settings allow wget connections
- The script will provide specific error codes and suggestions

### Compilation Errors

If compilation fails:

- Ensure all dependencies are installed
- Check system disk space (compilation requires ~500MB)
- Review error messages for missing development libraries

### Permission Issues

The script must be run as root:

```bash
sudo ./install_python_universal.sh
```

## Uninstallation

To remove the installed Python version:

```bash
sudo rm -rf /usr/local/bin/python3.X
sudo rm -rf /usr/local/bin/pip3.X
sudo rm -rf /usr/local/lib/python3.X
sudo rm -rf /usr/local/include/python3.X
sudo rm /etc/ld.so.conf.d/python3.X.conf
sudo ldconfig
```

Remove PATH entries from shell configuration files:

```bash
# Edit ~/.bashrc and ~/.zshrc to remove Python path entries
```

## Development Dependencies

The script installs the following development libraries:

- **Build Tools**: gcc, g++, make
- **SSL/TLS**: OpenSSL development files
- **Compression**: zlib, bzip2, xz/lzma
- **Database**: SQLite, GDBM
- **Interface**: readline, ncurses, tk
- **Core Libraries**: libffi, UUID (on supported systems)

## Security Considerations

- Script requires root privileges for system-wide installation
- Downloads are performed over HTTPS from python.org
- No binary packages are used; Python is compiled from source
- File integrity is verified through size checks

## Performance Notes

- Compilation uses all available CPU cores for faster builds
- `--enable-optimizations` increases build time but improves runtime performance
- Typical compilation time: 10-20 minutes depending on hardware
- Disk space required: ~500MB during installation, ~200MB after cleanup

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### Guidelines

- Maintain existing code style and conventions
- Test on multiple distributions before submitting
- Update documentation for any new features
- Preserve backward compatibility where possible

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

## Changelog

### Version 1.0.0
- Initial release
- Multi-distribution support
- Interactive version selection
- Comprehensive error handling
- Automatic dependency management
- System configuration and integration

## Acknowledgments

- Python Software Foundation for Python source distributions
- Linux distribution maintainers for package management tools
- Community contributors for testing and feedback
