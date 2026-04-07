#!/bin/zsh

set -euo pipefail

PYTHON_VERSION="3.14.3"
PYTHON_ABI_VERSION="3.14"
PKG_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-macos11.pkg"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="${ROOT_DIR}/vendor"
FRAMEWORK_DIR="${VENDOR_DIR}/Python.framework"
PKG_PATH="/tmp/python-${PYTHON_VERSION}-macos11.pkg"
EXPAND_DIR="/tmp/pythonpkg_${PYTHON_VERSION}_$RANDOM"

mkdir -p "${VENDOR_DIR}"

if [[ ! -f "${PKG_PATH}" ]]; then
	curl -L "${PKG_URL}" -o "${PKG_PATH}"
fi

rm -rf "${EXPAND_DIR}"
pkgutil --expand-full "${PKG_PATH}" "${EXPAND_DIR}"

rm -rf "${FRAMEWORK_DIR}"
ditto "${EXPAND_DIR}/Python_Framework.pkg/Payload" "${FRAMEWORK_DIR}"
find "${FRAMEWORK_DIR}" -name _CodeSignature -type d -prune -exec rm -rf {} +

ruby - "${FRAMEWORK_DIR}" "${PYTHON_ABI_VERSION}" <<'RUBY'
require "find"
require "pathname"

framework_root = Pathname(ARGV.fetch(0)).realpath
abi_version = ARGV.fetch(1)
old_prefix = "/Library/Frameworks/Python.framework/Versions/#{abi_version}"
new_prefix = "@rpath/Python.framework/Versions/#{abi_version}"
version_root = framework_root.join("Versions", abi_version)
mach_o_files = []

Find.find(framework_root.to_s) do |path|
  next unless File.file?(path)

  description = IO.popen(["/usr/bin/file", "-b", path], &:read)
  mach_o_files << path if description.include?("Mach-O")
end

mach_o_files.each do |path|
  dylib_id_lines = IO.popen(["/usr/bin/otool", "-D", path], err: File::NULL, &:read).lines.map(&:strip)
  dylib_id = dylib_id_lines[1]

  if dylib_id&.start_with?(old_prefix)
    relative_id = dylib_id.delete_prefix("#{old_prefix}/")
    system("/usr/bin/install_name_tool", "-id", "#{new_prefix}/#{relative_id}", path) or raise "install_name_tool -id failed for #{path}"
  end

  current_dir = Pathname(path).dirname
  dependencies = IO.popen(["/usr/bin/otool", "-L", path], &:read).lines.drop(1).map { |line| line.strip.split(/\s+/, 2).first }

  dependencies.each do |dependency|
    next unless dependency&.start_with?(old_prefix)

    relative_target = dependency.delete_prefix("#{old_prefix}/")
    new_target = "@loader_path/#{version_root.join(relative_target).relative_path_from(current_dir)}"
    system("/usr/bin/install_name_tool", "-change", dependency, new_target, path) or raise "install_name_tool -change failed for #{path}"
  end
end
RUBY

find "${FRAMEWORK_DIR}" -type f -print0 | while IFS= read -r -d '' path; do
	if /usr/bin/file -b "${path}" | /usr/bin/grep -q "Mach-O"; then
		/usr/bin/codesign --force --sign - "${path}"
	fi
done

/usr/bin/codesign --force --deep --sign - "${FRAMEWORK_DIR}"

rm -rf "${EXPAND_DIR}"

echo "Vendored ${FRAMEWORK_DIR}"
