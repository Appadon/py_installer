#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/usr/local"
TEMP_DIR="/tmp/python_install"

print_header() {
	: '
	Prints a formatted header message with informational text
	
	Args:
		$1: Header text to display
	
	Returns:
		None
	'
	echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
	echo -e "${BLUE}  $1${NC}"
	echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

print_success() {
	: '
	Prints a success message in green color
	
	Args:
		$1: Success message to display
	
	Returns:
		None
	'
	echo -e "${GREEN}[-] $1${NC}"
}

print_error() {
	: '
	Prints an error message in red color
	
	Args:
		$1: Error message to display
	
	Returns:
		None
	'
	echo -e "${RED}[X] $1${NC}"
}

print_warning() {
	: '
	Prints a warning message in yellow color
	
	Args:
		$1: Warning message to display
	
	Returns:
		None
	'
	echo -e "${YELLOW}[W] $1${NC}"
}

print_info() {
	: '
	Prints an informational message in blue color
	
	Args:
		$1: Info message to display
	
	Returns:
		None
	'
	echo -e "${BLUE}[I] $1${NC}"
}

fetch_available_versions() {
	: '
	Fetches available Python versions from python.org and allows user selection
	
	Queries python.org FTP server for available Python versions, displays the
	latest 10 versions, and prompts the user to select a version or use the default.
	Updates PYTHON_VERSION and PYTHON_URL globals based on user selection.
	
	Args:
		None
	
	Returns:
		0 on success
		1 if versions could not be fetched
	
	Globals Modified:
		PYTHON_VERSION: Updated if user selects a different version
		PYTHON_URL: Updated to match the selected version
	'
	print_header "Fetching Available Python Versions"
	
	if ! command -v curl >/dev/null 2>&1; then
		print_warning "curl not found, cannot fetch versions"
		print_info "Using default version: ${PYTHON_VERSION}"
		return 1
	fi
	
	print_info "Checking python.org for latest versions..."
	
	local versions=$(curl -s https://www.python.org/ftp/python/ | \
					 grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+(?=/)' | \
					 sort -V -r | \
					 head -n 10)
	
	if [ -z "$versions" ]; then
		print_warning "Could not fetch versions from python.org"
		print_info "Using default version: ${PYTHON_VERSION}"
		return 1
	fi
	
	echo ""
	print_info "Available Python versions (showing latest 10):"
	echo ""
	
	local count=1
	local version_array=()
	
	while IFS= read -r version; do
		echo "  ${count}) Python ${version}"
		version_array+=("$version")
		((count++))
	done <<< "$versions"
	
	echo ""
	echo "  0) Use default (${PYTHON_VERSION})"
	echo ""
	
	read -p "Select version [0-10]: " -n 2 -r selection
	echo ""
	
	if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#version_array[@]}" ]; then
		PYTHON_VERSION="${version_array[$((selection-1))]}"
		PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"
		print_success "Selected Python ${PYTHON_VERSION}"
	else
		print_info "Using default version: ${PYTHON_VERSION}"
	fi
	
	echo ""
}

verify_python_version() {
	: '
	Verifies that the specified Python version tarball is available for download
	
	Checks the HTTP status code of the Python tarball URL to ensure it exists
	and is downloadable. If the tarball is not available, provides helpful
	information about available files and allows the user to try a different version.
	
	Args:
		None
	
	Returns:
		0 if tarball is available
		1 if user wants to try a different version
		exits if user chooses not to retry
	
	Globals Read:
		PYTHON_VERSION: The Python version to verify
		PYTHON_URL: The URL to check for availability
	'
	print_header "Verifying Python Version Availability"
	
	print_info "Checking if Python ${PYTHON_VERSION} tarball is available..."
	
	local http_code=$(curl -s -o /dev/null -w "%{http_code}" -I "$PYTHON_URL")
	
	if [ "$http_code" -eq 200 ]; then
		print_success "Python ${PYTHON_VERSION} tarball is available"
		return 0
	elif [ "$http_code" -eq 404 ]; then
		print_error "Python ${PYTHON_VERSION} tarball not found!"
		print_warning "The version directory exists but the .tar.xz file is not available yet"
		print_info "This usually means the version is announced but not yet released"
		print_info "URL checked: $PYTHON_URL"
		
		print_info "Checking what files are available for this version..."
		local available_files=$(curl -s "https://www.python.org/ftp/python/${PYTHON_VERSION}/" | \
							   grep -oP '(?<=href=")[^"]*\.tar\.xz(?=")')
		
		if [ -n "$available_files" ]; then
			print_info "Available files in Python ${PYTHON_VERSION} directory:"
			echo "$available_files" | while read -r file; do
				echo "  - $file"
			done
		else
			print_warning "No .tar.xz files found in the version directory"
		fi
		
		echo ""
		print_info "Suggestions:"
		print_info "  1. Try a different Python version"
		print_info "  2. Check https://www.python.org/downloads/ for release status"
		print_info "  3. Wait for the official release"
		echo ""
		
		read -p "Do you want to try a different version? [y/N] " -n 1 -r
		echo ""
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			return 1
		else
			exit 1
		fi
	else
		print_warning "Unexpected HTTP response code: $http_code"
		print_info "Proceeding anyway, but download may fail"
		return 0
	fi
}

detect_distro() {
	: '
	Detects the Linux distribution and sets distribution variables
	
	Reads distribution information from system files (/etc/os-release,
	/etc/arch-release, or /etc/debian_version) and sets DISTRO and
	DISTRO_PRETTY global variables.
	
	Args:
		None
	
	Returns:
		None
	
	Globals Modified:
		DISTRO: Short name of the detected distribution
		DISTRO_PRETTY: Human-readable name of the distribution
	'
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		DISTRO=$ID
		DISTRO_PRETTY=$PRETTY_NAME
	elif [ -f /etc/arch-release ]; then
		DISTRO="arch"
		DISTRO_PRETTY="Arch Linux"
	elif [ -f /etc/debian_version ]; then
		DISTRO="debian"
		DISTRO_PRETTY="Debian"
	else
		DISTRO="unknown"
		DISTRO_PRETTY="Unknown Linux"
	fi
	
	print_info "Detected: ${DISTRO_PRETTY}"
}

install_dependencies_apt() {
	: '
	Installs Python build dependencies using apt package manager
	
	Installs all required development tools and libraries needed to
	compile Python from source on Debian-based distributions.
	
	Args:
		None
	
	Returns:
		None
	'
	print_info "Using apt package manager..."
	apt-get update
	apt-get install -y build-essential wget tar \
		libssl-dev zlib1g-dev libncurses5-dev libncursesw5-dev \
		libreadline-dev libsqlite3-dev libgdbm-dev libdb5.3-dev \
		libbz2-dev libexpat1-dev liblzma-dev tk-dev libffi-dev \
		uuid-dev
}

install_dependencies_pacman() {
	: '
	Installs Python build dependencies using pacman package manager
	
	Installs all required development tools and libraries needed to
	compile Python from source on Arch-based distributions.
	
	Args:
		None
	
	Returns:
		None
	'
	print_info "Using pacman package manager..."
	pacman -Sy --noconfirm
	pacman -S --needed --noconfirm \
		base-devel wget tar openssl zlib xz bzip2 \
		readline sqlite gdbm db expat libffi tk ncurses
}

install_dependencies_dnf() {
	: '
	Installs Python build dependencies using dnf package manager
	
	Installs all required development tools and libraries needed to
	compile Python from source on Fedora and modern RHEL-based distributions.
	
	Args:
		None
	
	Returns:
		None
	'
	print_info "Using dnf package manager..."
	dnf groupinstall -y "Development Tools"
	dnf install -y wget tar openssl-devel bzip2-devel libffi-devel \
		zlib-devel readline-devel sqlite-devel ncurses-devel \
		gdbm-devel xz-devel tk-devel libuuid-devel
}

install_dependencies_yum() {
	: '
	Installs Python build dependencies using yum package manager
	
	Installs all required development tools and libraries needed to
	compile Python from source on older RHEL-based distributions.
	
	Args:
		None
	
	Returns:
		None
	'
	print_info "Using yum package manager..."
	yum groupinstall -y "Development Tools"
	yum install -y wget tar openssl-devel bzip2-devel libffi-devel \
		zlib-devel readline-devel sqlite-devel ncurses-devel \
		gdbm-devel xz-devel tk-devel
}

install_dependencies() {
	: '
	Installs Python build dependencies based on detected distribution
	
	Determines the appropriate package manager for the detected distribution
	and installs all necessary dependencies for compiling Python from source.
	Exits with error if distribution is not supported.
	
	Args:
		None
	
	Returns:
		None
		exits with status 1 if distribution is unsupported
	
	Globals Read:
		DISTRO: The detected distribution identifier
	'
	print_header "Installing Dependencies"
	
	case "$DISTRO" in
		ubuntu|debian|linuxmint|pop)
			install_dependencies_apt
			;;
		arch|manjaro|endeavouros)
			install_dependencies_pacman
			;;
		fedora)
			install_dependencies_dnf
			;;
		centos|rhel|rocky|almalinux)
			if command -v dnf >/dev/null 2>&1; then
				install_dependencies_dnf
			else
				install_dependencies_yum
			fi
			;;
		*)
			print_error "Unsupported distribution: $DISTRO"
			print_info "Please install dependencies manually:"
			print_info "  - build-essential/base-devel"
			print_info "  - openssl, zlib, readline, sqlite, libffi, etc."
			exit 1
			;;
	esac
	
	print_success "Dependencies installed"
}

download_python() {
	: '
	Downloads and extracts the Python source tarball
	
	Creates a temporary directory, downloads the Python tarball from python.org,
	verifies the file size, and extracts the archive. Includes comprehensive
	error handling for network issues, corrupted downloads, and extraction failures.
	
	Args:
		None
	
	Returns:
		None
		exits with status 1 on download or extraction failure
	
	Globals Read:
		PYTHON_VERSION: Version of Python to download
		PYTHON_URL: URL of the Python tarball
		TEMP_DIR: Directory for temporary files
	'
	print_header "Downloading Python ${PYTHON_VERSION}"
	
	mkdir -p "$TEMP_DIR"
	cd "$TEMP_DIR"
	
	rm -f Python-${PYTHON_VERSION}.tar.xz*
	
	print_info "Downloading from: $PYTHON_URL"
	
	if wget --progress=bar:force --tries=3 --timeout=30 "$PYTHON_URL" 2>&1 | tail -f -n +6; then
		print_success "Download complete"
	else
		local wget_exit_code=$?
		print_error "Failed to download Python (wget exit code: $wget_exit_code)"
		
		case $wget_exit_code in
			4)
				print_error "Network failure - check your internet connection"
				;;
			8)
				print_error "Server error - the file may not exist on the server"
				print_info "This often happens with newly announced versions"
				;;
			*)
				print_error "Download failed with unknown error"
				;;
		esac
		
		exit 1
	fi
	
	if [ ! -f "Python-${PYTHON_VERSION}.tar.xz" ]; then
		print_error "Download file not found: Python-${PYTHON_VERSION}.tar.xz"
		print_warning "Check if the version is actually released"
		exit 1
	fi
	
	local file_size=$(stat -f%z "Python-${PYTHON_VERSION}.tar.xz" 2>/dev/null || stat -c%s "Python-${PYTHON_VERSION}.tar.xz" 2>/dev/null)
	if [ "$file_size" -lt 1000000 ]; then
		print_error "Downloaded file is too small (${file_size} bytes) - likely corrupted or incomplete"
		print_info "Expected size: ~20-25 MB"
		exit 1
	fi
	
	print_success "Downloaded file size: $(echo "scale=2; $file_size/1048576" | bc) MB"
	
	print_info "Extracting archive..."
	if tar -xf "Python-${PYTHON_VERSION}.tar.xz" 2>&1; then
		print_success "Extraction successful"
	else
		print_error "Extraction failed - file may be corrupted"
		print_info "Try running the script again to re-download"
		exit 1
	fi
	
	if [ ! -d "Python-${PYTHON_VERSION}" ]; then
		print_error "Extraction failed - directory not found"
		print_warning "The tarball extracted but the expected directory doesn't exist"
		exit 1
	fi
	
	print_success "Extraction complete"
}

compile_python() {
	: '
	Configures, compiles, and installs Python from source
	
	Configures Python with optimizations enabled, compiles using all available
	CPU cores, and performs an altinstall to avoid overwriting system Python.
	The build includes shared library support and pip installation.
	
	Args:
		None
	
	Returns:
		None
	
	Globals Read:
		PYTHON_VERSION: Version of Python being compiled
		INSTALL_DIR: Target installation directory
		TEMP_DIR: Directory containing extracted source
	'
	print_header "Compiling Python ${PYTHON_VERSION}"
	
	cd "$TEMP_DIR/Python-${PYTHON_VERSION}"
	
	print_info "Configuring build..."
	./configure --prefix="$INSTALL_DIR" \
				--enable-optimizations \
				--with-ensurepip=install \
				--enable-shared \
				LDFLAGS="-Wl,-rpath ${INSTALL_DIR}/lib"
	
	print_success "Configuration complete"
	
	local cpu_cores=$(nproc 2>/dev/null || echo 2)
	print_info "Compiling with ${cpu_cores} CPU cores..."
	print_warning "This will take 10-20 minutes..."
	
	make -j"$cpu_cores"
	
	print_success "Compilation complete"
	
	print_info "Installing Python..."
	make altinstall
	
	print_success "Installation complete"
}

setup_pip() {
	: '
	Configures pip and installs virtualenv for the new Python installation
	
	Verifies the Python binary installation, upgrades pip to the latest version,
	and installs virtualenv to enable virtual environment creation.
	
	Args:
		None
	
	Returns:
		None
		exits with status 1 if Python binary is not found
	
	Globals Read:
		PYTHON_VERSION: Version of Python that was installed
		INSTALL_DIR: Directory where Python was installed
	'
	print_header "Setting Up pip and Virtual Environment"
	
	local python_bin="${INSTALL_DIR}/bin/python${PYTHON_VERSION%.*}"
	
	if [ -f "$python_bin" ]; then
		print_success "Python ${PYTHON_VERSION%.*} installed at: $python_bin"
		$python_bin --version
	else
		print_error "Python binary not found at $python_bin"
		exit 1
	fi
	
	print_info "Upgrading pip..."
	$python_bin -m pip install --upgrade pip
	
	print_success "pip upgraded"
	
	print_info "Installing virtualenv..."
	$python_bin -m pip install virtualenv
	
	print_success "virtualenv installed"
}

configure_system() {
	: '
	Configures system libraries and shell environments for the new Python
	
	Updates the dynamic linker cache to include Python libraries and adds
	Python bin directory to PATH in bash and zsh configuration files.
	
	Args:
		None
	
	Returns:
		None
	
	Globals Read:
		PYTHON_VERSION: Version of Python that was installed
		INSTALL_DIR: Directory where Python was installed
	'
	print_header "Configuring System"
	
	print_info "Updating library cache..."
	echo "${INSTALL_DIR}/lib" > "/etc/ld.so.conf.d/python${PYTHON_VERSION}.conf"
	ldconfig
	
	print_success "Library cache updated"
	
	print_info "Updating shell configuration..."
	for config in "$HOME/.bashrc" "$HOME/.zshrc"; do
		if [ -f "$config" ]; then
			if ! grep -q "${INSTALL_DIR}/bin" "$config"; then
				echo "" >> "$config"
				echo "# ${PYTHON_VERSION%.*}" >> "$config"
				echo "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> "$config"
				print_success "Updated: $config"
			fi
		fi
	done
	
	print_success "System configured"
}

cleanup() {
	: '
	Removes temporary installation files
	
	Deletes the temporary directory and all downloaded/extracted files
	used during the Python installation process.
	
	Args:
		None
	
	Returns:
		None
	
	Globals Read:
		TEMP_DIR: Directory containing temporary files
	'
	print_info "Cleaning up temporary files..."
	rm -rf "$TEMP_DIR"
	print_success "Cleanup complete"
}

print_summary() {
	: '
	Displays installation summary and usage instructions
	
	Prints a formatted summary showing the installed Python version,
	installation paths, and quick start commands for using the new
	Python installation.
	
	Args:
		None
	
	Returns:
		None
	
	Globals Read:
		PYTHON_VERSION: Version of Python that was installed
		DISTRO_PRETTY: Human-readable distribution name
		INSTALL_DIR: Directory where Python was installed
	'
	echo ""
	print_header "Installation Summary"
	echo ""
	print_success "Python ${PYTHON_VERSION} Successfully Installed!"
	echo ""
	print_info "Installation Details:"
	echo "  • Distribution: ${DISTRO_PRETTY}"
	echo "  • Python: ${INSTALL_DIR}/bin/python${PYTHON_VERSION%.*}"
	echo "  • pip: ${INSTALL_DIR}/bin/pip${PYTHON_VERSION%.*}"
	echo ""
	print_info "Quick Start:"
	echo "  python${PYTHON_VERSION%.*} --version"
	echo "  python${PYTHON_VERSION%.*} -m venv myenv"
	echo "  source myenv/bin/activate"
	echo ""
	print_warning "Restart your terminal or run: source ~/.bashrc"
	echo ""
}

main() {
	: '
	Main execution function orchestrating the Python installation process
	
	Verifies root privileges, allows version selection, detects the Linux
	distribution, confirms installation with the user, and executes the
	complete installation workflow including dependency installation,
	Python compilation, configuration, and cleanup.
	
	Args:
		None
	
	Returns:
		None
		exits with status 1 if not run as root or user cancels
	'
	if [[ $EUID -ne 0 ]]; then
		print_error "This script must be run as root (use sudo)"
		exit 1
	fi

	fetch_available_versions

    while ! verify_python_version; do
        fetch_available_versions
    done
	
	print_header "Python ${PYTHON_VERSION} Universal Installer"
	echo ""
	
	detect_distro
	
	echo ""
	read -p "Continue with installation? [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		print_info "Installation cancelled"
		exit 0
	fi
	
	install_dependencies
	download_python
	compile_python
	setup_pip
	configure_system
	cleanup
	print_summary
	
	print_success "All done!"
}

main
