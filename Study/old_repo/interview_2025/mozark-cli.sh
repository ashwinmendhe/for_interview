#!/bin/bash

# Get the directory where the script is located
os_type=$(uname)
cli_tag=v3.5.0
binaries=v3.2.0
username="mozark"
password="Mozark@1234"
MONGO_SCRIPT=$(mktemp)
WEBCAM_SCRIPT=$(mktemp)
AUDIO_SCRIPT=$(mktemp)
BLUETOOTH_SCRIPT=$(mktemp)
TAG_UPGREADER_SCRIPT=$(mktemp)
SERVICE_APP="run-app"
SERVICE_DIRECTOR="run-director"
script_dir="$(pwd)"
TAG_URL="https://operation.mozark.ai/v1/tag/"

base_path="$script_dir/deployment/$cli_tag/mozark-cli-$cli_tag"
venv_path="$base_path/venv/bin/activate"
script_path="app-testing-controller-stack/controller_software/index.py"

version=$(echo "$cli_tag" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
if [[ $(printf '%s\n' "3.6.0" "$version" | sort -V | head -n1) == "3.6.0" ]]; then
    venv_path="$base_path/app-testing-controller-stack/.venv/bin/activate"
fi

SELF_UPGRADE_SCRIPT=$(mktemp)
SELF="$script_dir/mozark-cli.sh"

echo "OS Type      : $os_type"
echo "CLI Tag      : $cli_tag"
echo "Binaries Tag : $binaries"



# Function to check if both services are running
check_services() {
    local service1="$1"
    local service2="$2"

    local service1_running=false
    local service2_running=false

    if ps -ef | grep "$service1" | grep -v "grep" > /dev/null; then
        service1_running=true
    fi

    if ps -ef | grep "$service2" | grep -v "grep" > /dev/null; then
        service2_running=true
    fi

    echo "====== Checking Services Status ======"
    if $service1_running && $service2_running; then
        echo " $service1 : ✅ Running."
        echo " $service2 : ✅ Running."
    elif $service1_running; then
        #echo "⚠️ $service1 is running, but $service2 is NOT running."
        echo " $service1 : ✅ Running."
        echo " $service2 : ❌ Not Running."
    elif $service2_running; then
        echo " $service1 : ❌ Not Running."
        echo " $service2 : ✅ Running."
    else
        echo " $service1 :❌ Not Running."
        echo " $service2 :❌ Not Running."
    fi
}


config () {
    JSON_FILE="$script_dir/config.json"
    # Extract tenantName using jq
    tenant=$(jq -r '.["app-testing"].tenantName' "$JSON_FILE")
    echo "$tenant"
}

mongo_status() {
    device_id=$1
    tenant=$2

    # Check if python3 has pymongo, otherwise fallback to python3.11
    if command -v python3 &>/dev/null && python3 -c "import pymongo" &>/dev/null; then
        PYTHON_CMD="python3"
    elif command -v python3.11 &>/dev/null && python3.11 -c "import pymongo" &>/dev/null; then
        PYTHON_CMD="python3.11"
    else
        echo "Error: Neither python3 nor python3.11 has pymongo installed."
        exit 1
    fi

    # Execute the Python script with the selected Python version
    device_status=$("$PYTHON_CMD" "$MONGO_SCRIPT" "$device_id" "$tenant")
    echo "$device_status"
}


webcam_id() {
    PYTHON_CMD="python3"
    #WEBCAM_COMMAND=$script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/app-testing-controller-stack/bin/release-$binaries/gst/gst-device-lookup --video --list
    # Execute the Python script with the selected Python version
    WEBCAM_DEVICES=$("$PYTHON_CMD" "$WEBCAM_SCRIPT")
    echo "$WEBCAM_DEVICES"
}

audio_id() {
    PYTHON_CMD="python3"
    #AUDIO_COMMAND=$script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/app-testing-controller-stack/bin/release-$binaries/gst/gst-device-lookup --audio --list
    # Execute the Python script with the selected Python version
    AUDIO_DEVICES=$("$PYTHON_CMD" "$AUDIO_SCRIPT")
    echo "$AUDIO_DEVICES"
}

bluetooth_id() {
    PYTHON_CMD="python3"
    # Execute the Python script with the selected Python version
    BLUETOOTH_DEVICES=$("$PYTHON_CMD" "$BLUETOOTH_SCRIPT")
    echo "$BLUETOOTH_DEVICES"
}


check_devices_status() {
    tenant=$(config)

    # Check Android devices
    echo "====== Checking Android devices ======"
    android_devices=$(adb devices -l | awk 'NR>1 {print $1}' | grep -v '^$')
    
    # Check iPhone devices
    echo "====== Checking iPhone devices ======"
    iphone_devices=$(idevice_id | awk '{print $1}')

    # Count devices
    android_count=$(echo "$android_devices" | grep -c . || echo 0)
    iphone_count=$(echo "$iphone_devices" | grep -c . || echo 0)

    echo "Total connected Android devices: $android_count"
    echo "Total connected iPhone devices: $iphone_count"

    # If no devices are connected, show message and exit
    if [[ "$android_count" -eq 0 && "$iphone_count" -eq 0 ]]; then
        echo "❌ No devices connected on your system! Please connect a device or enable developer option."
        exit 1
    fi

    # Process Android devices
    for device_id in $android_devices; do
        if [[ -n "$device_id" ]]; then
            device_status=$(mongo_status "$device_id" "$tenant")
            if [[ "$device_status" == "None" ]]; then
                echo "Android Device ID: $device_id : ✅ connected, $tenant DB : ❌ Not Added."
            else
                if [[ "$device_status" == "unavailable" ]]; then
                    echo "Android Device ID: $device_id : ✅ connected, status : ❌ $device_status"
                else
                    echo "Android Device ID: $device_id : ✅ connected, status : ✅ $device_status"
                fi
            fi
        fi
    done

    # Process iPhone devices
    echo ""
    for device_id in $iphone_devices; do
        if [[ -n "$device_id" ]]; then
            device_status=$(mongo_status "$device_id" "$tenant")
            if [[ "$device_status" == "None" ]]; then
                echo "iPhone Device ID: $device_id : ✅ connected, $tenant DB : ❌ Not Added.."
            else
                if [[ "$device_status" == "unavailable" ]]; then
                    echo "iPhone Device ID: $device_id : ✅ connected, status : ❌ $device_status"
                else
                    echo "iPhone Device ID: $device_id : ✅ connected, status : ✅ $device_status"
                fi
            fi
        fi
    done
}



tag_upgreader() {
    cli_tag=$1
    binaries=$2
    PYTHON_CMD="python3"
    #WEBCAM_COMMAND=$script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/app-testing-controller-stack/bin/release-$binaries/gst/gst-device-lookup --video --list
    # Execute the Python script with the selected Python version
    tag_status=$("$PYTHON_CMD" "$TAG_UPGREADER_SCRIPT" "$cli_tag" "$binaries")
    echo "$tag_status"
}


# Write Python script For device status in mongo
cat <<EOF > "$MONGO_SCRIPT"
from pymongo import MongoClient
import json
import sys # Needed to capture command-line arguments

# MongoDB connection
mongo_link = "mongodb+srv://mozark-mongo:9bZu8T5ZHMy3Vn1R@cluster0.dlbyh.mongodb.net/event-data?authSource=admin" \
             "&replicaSet=atlas-yjhvlo-shard-0&readPreference=primary&ssl=true"

tenant = sys.argv[2]  # Get device_id passed from Bash
device_id = sys.argv[1]  # Get device_id passed from Bash
query = {'uuid': device_id}

def getMongo(tenant, mongo_link, query): 
    client = MongoClient(mongo_link)
    db = client[f"{tenant}-app-testing"]
    collection = db[f"{tenant}-test-devices"]
    results = list(collection.find(query))

    if results:
        device_status = results[0]['deviceParameters']['deviceStatus']
        return device_status
    else:
        device_status=None
        return device_status

# Call function and print the result (Bash captures this)
device_status = getMongo(tenant, mongo_link, query)
print(device_status)
EOF


# Write Python script For Webcan device list
cat <<EOF > "$WEBCAM_SCRIPT"
import subprocess

def get_logitech_brio_serial():
    # Run the command and capture the output
    # result = subprocess.run(["./gst-device-lookup", "--list", "--video"], capture_output=True, text=True)
    result = subprocess.run(["$script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/app-testing-controller-stack/bin/release-$binaries/gst/gst-device-lookup", "--list", "--video"], capture_output=True, text=True)
    
    lines = result.stdout.split("\n")
    table_start = False
    logitech_brio_list = []  # List to store matching devices

    for line in lines:
        if "deviceName" in line:  # Start capturing when table header appears
            table_start = True
            continue  # Skip the header line
        
        if table_start:
            columns = line.split()  # Split columns by whitespace
            if len(columns) >= 2:  # Ensure there are enough columns
                device_name = " ".join(columns[:-3])  # Device name can have spaces
                serial_id = columns[-3]  # Serial ID is the third-last column

                # Filter only Logitech BRIO devices
                if device_name == "Logitech BRIO":
                    logitech_brio_list.append(serial_id)

    # Format output list
    output_lines = ["Webcam Devices and Serial IDs", "-" * 30]

    if logitech_brio_list:
        for idx, serial in enumerate(logitech_brio_list, start=1):
            output_lines.append(f"{idx}. Logitech BRIO : {serial}")
        output_lines.append(f"\nTotal Logitech BRIO Devices: {len(logitech_brio_list)}")
    else:
        output_lines.append("No Logitech BRIO devices found.")

    return "\n".join(output_lines)

# Call function and print result
brio_list = get_logitech_brio_serial()
print(brio_list)

EOF


# Write Python script For Audio device list
cat <<EOF > "$AUDIO_SCRIPT"
import subprocess

def get_logitech_brio_serial():
    # Run the command and capture the output
    # result = subprocess.run(["./gst-device-lookup", "--list", "--audio"], capture_output=True, text=True)
    result = subprocess.run(["$script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/app-testing-controller-stack/bin/release-$binaries/gst/gst-device-lookup", "--list", "--audio"], capture_output=True, text=True)
    
    lines = result.stdout.split("\n")
    table_start = False
    logitech_brio_list = []  # List to store matching devices

    for line in lines:
        if "deviceName" in line:  # Start capturing when table header appears
            table_start = True
            continue  # Skip the header line
        
        if table_start:
            columns = line.split()  # Split columns by whitespace
            if len(columns) >= 2:  # Ensure there are enough columns
                device_name = " ".join(columns[:-3])  # Device name can have spaces
                serial_id = columns[-3]  # Serial ID is the third-last column

                # Filter only Logitech BRIO devices
                if device_name == "Logitech BRIO":
                    logitech_brio_list.append(serial_id)

    # Format output list
    output_lines = ["Webcam Devices and Serial IDs", "-" * 30]

    if logitech_brio_list:
        for idx, serial in enumerate(logitech_brio_list, start=1):
            output_lines.append(f"{idx}. Logitech BRIO : {serial}")
        output_lines.append(f"\nTotal Logitech BRIO Devices: {len(logitech_brio_list)}")
    else:
        output_lines.append("No Logitech BRIO devices found.")

    return "\n".join(output_lines)

# Call function and print result
brio_list = get_logitech_brio_serial()
print(brio_list)

EOF


# Write Python script For Webcan device list
cat <<EOF > "$BLUETOOTH_SCRIPT"
import subprocess
import re

def get_nrf_devices():
    # Run the nrfutil command and capture the output
    result = subprocess.run(["nrfutil", "device", "list"], capture_output=True, text=True)
    
    lines = result.stdout.split("\n")
    devices = []
    current_device = None

    for line in lines:
        line = line.strip()

        # Ignore warning messages
        if "WARNING:" in line or "JLink" in line:
            continue

        # Match serial number (First line of each device block)
        serial_match = re.match(r"^[A-Z0-9]+$", line)
        if serial_match:
            if current_device:
                devices.append(current_device)  # Store previous device
            current_device = {"serial": line}  # Start new device entry

        # Capture the product name
        if "product" in line:
            current_device["product"] = line.split("product")[1].strip()

    # Add the last device found
    if current_device:
        devices.append(current_device)

    # Format output list
    output_lines = ["Connected Devices", "-----------------"]

    if devices:
        for idx, device in enumerate(devices, start=1):
            output_lines.append(f"{idx}. {device['product']} : {device['serial']}")
        output_lines.append(f"\nTotal Devices: {len(devices)}")
    else:
        output_lines.append("No supported devices found.")

    return "\n".join(output_lines)

# Call function and print result
device_list = get_nrf_devices()
print(device_list)
EOF


# Write Python script For tag update in rds
cat <<EOF > "$TAG_UPGREADER_SCRIPT"
import requests
import json
from datetime import datetime
import pytz
import platform
import json
import requests

URL = "$TAG_URL"

# CE = "3.4.0.beta2"
# BINARY = "3.2.0.beta9"
CE = "$cli_tag"
BINARY = "$binaries"


def get_data(URL, id=None):
    params = {}
    if id is not None:
        params['controller_id'] = id

    headers = {'Content-Type': 'application/json'}
    r = requests.get(url=URL, headers=headers, params=params)
    r.raise_for_status()
    
    data = r.json()

    # If it's a list, pick the latest record by timestamp
    if isinstance(data, list):
        if len(data) == 0:
            return None
        if len(data) == 1:
            return data[0]
        return max(
            data,
            key=lambda d: datetime.fromisoformat(d['current_CE_timestamp'])
            if d['current_CE_timestamp'] else datetime.min
        )

    # If it's already a dict, just return it
    return data

def get_tenant_data(URL, id=None):
    params = {}
    if id is not None:
        params['tenant_name'] = id

    headers = {'Content-Type': 'application/json'}
    r = requests.get(url=URL, headers=headers, params=params)
    r.raise_for_status()
    
    data = r.json()
    return data


def post_data(URL,data):
    
    json_data = json.dumps(data)
    headers = {'content-Type':'application/json'}
    r = requests.post(url = URL, headers=headers,data = json_data)
    data = r.json()
    # print("data created : ", data)
    return data

# Step 1: Initialize defaults
payload = {
"tenant_name": None,
"location": None,
"controller": None,
"controller_id": None,
"last_CE": None,
"last_binary": None,
"last_CE_timestamp": None,
"current_CE": None,
"current_binary": None,
"current_CE_timestamp": None,
"last_FE": None,
"last_FE_timestamp": None,
"current_FE": None,
"current_FE_timestamp": None,
"last_BE": None,
"last_BE_timestamp": None,
"current_BE": None,
"current_BE_timestamp": None,
"additional_field1": None,
"additional_field2": None,
"additional_field3": None
}

with open("$script_dir/config.json", "r") as f:
    config = json.load(f)
controller_id = config["app-testing"]["controllerId"]
data=get_data(URL,controller_id)

# print(tenant_data)
if data:
    payload["last_CE"] = data['current_CE']
    payload["last_CE_timestamp"] = data['current_CE_timestamp']
    payload["last_binary"] = data['current_binary']
    payload["current_FE"] = data['current_FE']
    payload["current_FE_timestamp"] = data['current_FE_timestamp']
    payload["current_BE"] = data['current_BE']
    payload["current_BE_timestamp"] = data['current_BE_timestamp']
    payload["last_FE"] = data['current_FE']
    payload["last_FE_timestamp"] = data['current_FE_timestamp']
    payload["last_BE"] = data['current_BE']
    payload["last_BE_timestamp"] = data['current_BE_timestamp']
else:
    tenant_data=get_tenant_data(URL,config["app-testing"]["tenantName"])
    if tenant_data:
        payload["current_FE"] = tenant_data[0]['current_FE']
        payload["current_FE_timestamp"] = tenant_data[0]['current_FE_timestamp']
        payload["current_BE"] = tenant_data[0]['current_BE']
        payload["current_BE_timestamp"] = tenant_data[0]['current_BE_timestamp']
        payload["last_FE"] = tenant_data[0]['current_FE']
        payload["last_FE_timestamp"] = tenant_data[0]['current_FE_timestamp']
        payload["last_BE"] = tenant_data[0]['current_BE']
        payload["last_BE_timestamp"] = tenant_data[0]['current_BE_timestamp']


ist = pytz.timezone('Asia/Kolkata')
payload["current_CE_timestamp"] = datetime.now(ist).strftime("%Y-%m-%dT%H:%M:%S")
# payload["current_CE_timestamp"] = datetime.now(ist).strftime("%Y-%m-%dT%H:%M:%S%z")

payload["tenant_name"] = config["app-testing"]["tenantName"]
payload["location"] = city = controller_id.split("-")[0]
payload["controller"] = "mac"
if platform.system().lower() == "linux":
    payload["controller"] = "linux"
payload["controller_id"] = controller_id
payload["current_CE"] = CE
payload["current_binary"] = BINARY
msg=post_data(URL,payload)
print("data created")
EOF



# script_dir="$(pwd)"

# # List of tools and their installation commands
#  tools=("python3.12" "wget" "scrcpy" "xcresultparser" "pstree" "opencv" "android-platform-tools" "idb" "ffmpeg" "libusbmuxd" "libimobiledevice" "gstreamer" "fb-idb" "idb-companion" "ideviceinstaller" "appium@1.21" "frontail" "xcpretty")
#  commands=("brew
#   install python@3.11" "brew
#   install wget" "brew install scrcpy" "brew install xcresultparser" "brew install pstree" "brew install opencv" "brew
#   install android-platform-tools" "brew
#   tap facebook/fb" "brew
#   install idb-companion" "sudo pip3 install fb-idb" "brew
#   install ffmpeg" "brew
#   install libusbmuxd" "brew
#   install libimobiledevice" "brew
#   install gstreamer" "sudo -H pip3 install fb-idb" "brew
#   tap facebook/fb" "brew
#   install idb-companion" "brew install ideviceinstaller" "sudo npm install -g appium@2.11.3" "sudo npm install -g frontail" "sudo gem install xcpretty")


# # Function to check and install a tool
#  check_and_install() {
#      tool=$1
#      command=$2

#      # Check if the tool is installed
#      if command -v "$tool" &> /dev/null; then
#          echo "$tool is already installed"
#      else
#          # Install the tool
#          $command
#          # Check installation success
#          if [ $? -eq 0 ]; then
#              echo "$tool installed successfully"
#          else
#              echo "Error installing $tool. Please manually install and proceed to the next."
#          fi
#      fi
#  }


# List of tools and their installation & cleanup commands
tools=("python3.12" "wget" "scrcpy" "xcresultparser" "pstree" "opencv" "android-platform-tools" "idb" "ffmpeg" "libusbmuxd" "libimobiledevice" "gstreamer" "fb-idb" "idb-companion" "ideviceinstaller" "appium" "frontail" "xcpretty")

# Installation commands (aligned by index)
install_cmds=(
  "brew install python@3.12"
  "brew install wget"
  "brew install scrcpy"
  "brew install xcresultparser"
  "brew install pstree"
  "brew install opencv"
  "brew install android-platform-tools"
  "brew tap facebook/fb && brew install idb-companion"
  "brew install ffmpeg"
  "brew install libusbmuxd"
  "brew install libimobiledevice"
  "brew install gstreamer"
  "pip3 install --upgrade fb-idb"
  "brew tap facebook/fb && brew install idb-companion"
  "brew install ideviceinstaller"
  "npm install -g appium@2.11.3"
  "npm install -g frontail"
  "gem install xcpretty"
)

# Cleanup/uninstall commands (aligned by index)
cleanup_cmds=(
  "brew uninstall --force python@3.12"
  "brew uninstall --force wget"
  "brew uninstall --force scrcpy"
  "brew uninstall --force xcresultparser"
  "brew uninstall --force pstree"
  "brew uninstall --force opencv"
  "brew uninstall --force android-platform-tools"
  "brew uninstall --force idb-companion"
  "brew uninstall --force ffmpeg"
  "brew uninstall --force libusbmuxd"
  "brew uninstall --force libimobiledevice"
  "brew uninstall --force gstreamer"
  "pip3 uninstall -y fb-idb"
  "brew uninstall --force idb-companion"
  "brew uninstall --force ideviceinstaller"
  "npm uninstall -g appium"
  "npm uninstall -g frontail"
  "gem uninstall -aIx xcpretty"
)

# Function to reinstall a tool
check_and_reinstall() {
    tool=$1
    install_cmd=$2
    cleanup_cmd=$3

    if command -v "$tool" &> /dev/null; then
        echo "🔄 $tool found, reinstalling..."
        eval "$cleanup_cmd"
    else
        echo "⬇️  $tool not found, installing fresh..."
    fi

    eval "$install_cmd"

    if [ $? -eq 0 ]; then
        echo "✅ $tool installed successfully"
    else
        echo "❌ Error installing $tool. Please check manually."
    fi
    echo "---------------------------------------------"
}




install_goios() {
    cd ~
    sudo gem install xcpretty
    git clone https://github.com/danielpaulus/go-ios.git
    cd go-ios
    sudo go build
    sudo cp go-ios /usr/local/bin/
}



mac_mozark_cli_package() {
    echo "====== Intalling mozark-cli package....."
    version=$(echo "$cli_tag" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    # if [[ $(printf '%s\n' "3.5.0" "$version" | sort -V | head -n1) == "3.5.0" ]]; then
    if [[ "$version" =~ ^3\.4\.0(\.beta[0-9]+)?$ || "$version" == "3.5.0" ]]; then
        echo "✅ Version $version is in the allowed range (3.4.0, beta, or 3.5.0)"
        HOMEBREW_NO_AUTO_UPDATE=1 brew install python@3.12
        echo "mozark-cli-$cli_tag.zip"
        echo "ce-binaries-$binaries.zip"

        # Define the zip file names
        cli_zip="mozark-cli-$cli_tag.zip"
        binaries_zip="ce-binaries-$binaries.zip"
        download_dir=~/Downloads

        cd ~/Downloads
        # Check if the CLI zip file already exists
        if [ -f "$download_dir/$cli_zip" ]; then
            echo "$cli_zip already exists. Skipping download."
        else
            echo "Downloading $cli_zip..."
            curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O \
                "https://api.bitbucket.org/2.0/repositories/mozarkai/app-testing-controller-stack/downloads/$cli_zip"
        fi

        # Check if the binaries zip file already exists
        if [ -f "$download_dir/$binaries_zip" ]; then
            echo "$binaries_zip already exists. Skipping download."
        else
            echo "Downloading $binaries_zip..."
            curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O \
                "https://api.bitbucket.org/2.0/repositories/mozarkai/app-testing-controller-stack/downloads/$binaries_zip"
        fi
        cd "$script_dir"
        echo "$script_dir"
        zip_file="mozark_cli_installer.zip"

        if [ -f "$zip_file" ]; then
            echo "$zip_file already exists. Skipping download and unzip."
            rm -rf $zip_file
            rm -rf mozark_cli_installer
            rm -rf __MACOSX
            echo "Deleted and Downloading again $zip_file..."
        else
            echo "Downloading $zip_file..."
        fi
        curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O \
            https://api.bitbucket.org/2.0/repositories/mozarkai/controller-deployment/downloads/$zip_file
        
        echo "Unzipping $zip_file..."
        unzip "$zip_file"
    
        mkdir -p deployment
        #brew install json-glib taglib faad2 faac librsvg opencv srtp openh264 librsvg
        #brew install python@3.12
        python_v=python3.12
        $python_v -m pip install --upgrade pip 
        $python_v "$script_dir/mozark_cli_installer/index.py" \
        --mozark_cli_path "$HOME/Downloads/mozark-cli-$cli_tag.zip" \
        --binaries_release_path "$HOME/Downloads/ce-binaries-$binaries.zip" \
        --deployment_dir "$script_dir/deployment" \
        --base_config "$script_dir/config.json" \
        -y       
    elif [[ $(printf '%s\n' "3.6.0" "$version" | sort -V | head -n1) == "3.6.0" ]]; then
        echo "⚠️ Version $version is 3.6.0 or greater (including pre-releases)"
        HOMEBREW_NO_AUTO_UPDATE=1 brew install python@3.12
        python_v=python3.12
        echo "mozark-cli-$cli_tag.zip"
        echo "binaries-release-$binaries.zip"

        # Define the zip file names
        cli_zip="mozark-cli-$cli_tag.zip"
        # binaries_zip="binaries-release-$binaries.zip"
        binaries_zip="ce-binaries-$binaries.zip"
        download_dir=~/Downloads

        cd ~/Downloads
        # Check if the CLI zip file already exists
        if [ -f "$download_dir/$cli_zip" ]; then
            echo "$cli_zip already exists. Skipping download."
        else
            echo "Downloading $cli_zip..."
            curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O \
                "https://api.bitbucket.org/2.0/repositories/mozarkai/app-testing-controller-stack/downloads/$cli_zip"
        fi

        # Check if the binaries zip file already exists
        if [ -f "$download_dir/$binaries_zip" ]; then
            echo "$binaries_zip already exists. Skipping download."
        else
            echo "Downloading $binaries_zip..."
            curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O \
                "https://api.bitbucket.org/2.0/repositories/mozarkai/app-testing-controller-stack/downloads/$binaries_zip"
        fi
        cd "$script_dir"
        echo "$script_dir"
        # zip_file="mozark_cli_installer_3.2.zip"
        zip_file="mozark_cli_installer.zip"
        if [ -f "$zip_file" ]; then
            echo "$zip_file already exists. Skipping download and unzip."
            rm -rf $zip_file
            rm -rf mozark_cli_installer
            rm -rf __MACOSX
            echo "Deleted and Downloading again $zip_file..."
        else
            echo "Downloading $zip_file..."
        fi
        curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O \
            https://api.bitbucket.org/2.0/repositories/mozarkai/controller-deployment/downloads/$zip_file
        
        echo "Unzipping $zip_file..."
        unzip "$zip_file"
    
        mkdir -p deployment
        $python_v -m pip install --upgrade pip 
        $python_v "$script_dir/mozark_cli_installer/index.py" \
        --mozark_cli_path "$HOME/Downloads/mozark-cli-$cli_tag.zip" \
        --binaries_release_path "$HOME/Downloads/ce-binaries-$binaries.zip" \
        --deployment_dir "$script_dir/deployment" \
        --base_config "$script_dir/config.json" \
        -y
    fi

    cd "$script_dir"
    curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O   https://api.bitbucket.org/2.0/repositories/mozarkai/controller-deployment/downloads/requirements_2.txt
    cd $script_dir/deployment/$cli_tag/mozark-cli-$cli_tag
    if [[ $(printf '%s\n' "3.6.0" "$version" | sort -V | head -n1) == "3.6.0" ]]; then
        echo "====== current not installing requirements_2.txt....."
        . app-testing-controller-stack/.venv/bin/activate

        pip3 install -r $script_dir/requirements_2.txt
        pip install --upgrade pip
        pip3 install -r $script_dir/requirements_2.txt
        pip install --upgrade pip
        pip3 install -r $script_dir/requirements_2.txt


        # $python_v -m ensurepip --upgrade
        # $python_v -m pip install --upgrade pip setuptools wheel
        # $python_v -m pip --version
        # $python_v -m pip install -r $script_dir/requirements_2.txt
        # pip install -r $script_dir/requirements_2.txt
        # pip3 install -r $script_dir/requirements_2.txt
    else
        echo "====== installing requirements_2.txt....."
        . venv/bin/activate
        pip3 install -r $script_dir/requirements_2.txt
        pip install --upgrade pip
        pip3 install -r $script_dir/requirements_2.txt
        pip install --upgrade pip
        pip3 install -r $script_dir/requirements_2.txt

        # $python_v -m ensurepip --upgrade
        # $python_v -m pip install --upgrade pip setuptools wheel
        # $python_v -m pip --version
        # $python_v -m pip install -r $script_dir/requirements_2.txt
        # pip install -r $script_dir/requirements_2.txt
        # pip3 install -r $script_dir/requirements_2.txt
    fi
}

linux_mozark_cli_package() {
    echo "====== Intalling mozark-cli package....."
    echo "mozark-cli-$cli_tag.zip"
    echo "ce-binaries-$binaries.zip"

    # Define the zip file names
    cli_zip="mozark-cli-$cli_tag.zip"
    binaries_zip="ce-binaries-$binaries.zip"
    download_dir=~/Downloads

    cd ~/Downloads
    # Check if the CLI zip file already exists
    if [ -f "$download_dir/$cli_zip" ]; then
        echo "$cli_zip already exists. Skipping download."
    else
        echo "Downloading $cli_zip..."
        curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O \
            "https://api.bitbucket.org/2.0/repositories/mozarkai/app-testing-controller-stack/downloads/$cli_zip"
    fi

    # Check if the binaries zip file already exists
    if [ -f "$download_dir/$binaries_zip" ]; then
        echo "$binaries_zip already exists. Skipping download."
    else
        echo "Downloading $binaries_zip..."
        curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O \
            "https://api.bitbucket.org/2.0/repositories/mozarkai/app-testing-controller-stack/downloads/$binaries_zip"
    fi
    cd "$script_dir"
    echo "$script_dir"
    zip_file="mozark_cli_installer.zip"

    if [ -f "$zip_file" ]; then
        echo "$zip_file already exists. Skipping download and unzip."
        rm -rf $zip_file
        rm -rf mozark_cli_installer
        rm -rf __MACOSX
        echo "Deleted and Downloading again $zip_file..."
    else
        echo "Downloading $zip_file..."
    fi
    curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O \
            https://api.bitbucket.org/2.0/repositories/mozarkai/controller-deployment/downloads/$zip_file
        
    echo "Unzipping $zip_file..."
    unzip "$zip_file"
    mkdir deployment
    pip install --upgrade pip
    python3 $script_dir/mozark_cli_installer/index.py \
    --mozark_cli_path ~/Downloads/mozark-cli-$cli_tag.zip \
    --binaries_release_path ~/Downloads/ce-binaries-$binaries.zip \
    --deployment_dir $script_dir/deployment \
    --base_config $script_dir/config.json \
    -y --ignore_invalid_wda_path
    cd "$script_dir"
    curl -s -S --user mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66 -L -O   https://api.bitbucket.org/2.0/repositories/mozarkai/controller-deployment/downloads/requirements_2.txt
    cd $script_dir/deployment/$cli_tag/mozark-cli-$cli_tag
    if [[ $(printf '%s\n' "3.6.0" "$version" | sort -V | head -n1) == "3.6.0" ]]; then
        echo "====== current not installing requirements_2.txt....."
        # . app-testing-controller-stack/.venv/bin/activate
        # pip3 install -r $script_dir/requirements_2.txt
        # pip install --upgrade pip
        # pip3 install -r $script_dir/requirements_2.txt
        # pip install --upgrade pip
        # pip3 install -r $script_dir/requirements_2.txt


        # . app-testing-controller-stack/.venv/bin/activate
        # $python_v -m ensurepip --upgrade
        # $python_v -m pip install --upgrade pip setuptools wheel
        # $python_v -m pip --version
        # $python_v -m pip install -r $script_dir/requirements_2.txt
        # pip install -r $script_dir/requirements_2.txt
        # pip3 install -r $script_dir/requirements_2.txt
    else
        echo "====== current not installing requirements_2.txt....."
        # . venv/bin/activate
        # pip3 install -r $script_dir/requirements_2.txt
        # pip install --upgrade pip
        # pip3 install -r $script_dir/requirements_2.txt
        # pip install --upgrade pip
        # pip3 install -r $script_dir/requirements_2.txt
    fi
}




mac_gst_stream_binary() {
    cd "$script_dir"
    echo "====== gstreamer binary coping ....."
    wget https://mozark-release-artifacts.s3.ap-south-1.amazonaws.com/mozark-desktop-app/gstreamer-3.0.0-beta1.mac.zip
    sudo cp gstreamer-3.0.0-beta1.mac.zip /opt
    cd ~
    cd /opt
    sudo unzip gstreamer-3.0.0-beta1.mac.zip
    sudo xattr -d com.apple.quarantine /opt/build/darwin_x86_64/lib/gdk-pixbuf-2.0/2.10.0/loaders/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/bin/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/lib/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/lib/gstreamer-1.0/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/lib/gstreamer-1.0/validate/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/lib/cairo/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/lib/gobject-introspection/giscanner/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/lib/engines-1.1/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/lib/engines-1.1/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/lib/gio/modules/*
    sudo xattr -d com.apple.quarantine /opt/build/dist/darwin_x86_64/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-svg.so
    echo 'export PATH="/opt/build/dist/darwin_x86_64/bin:$PATH"' >> ~/.zshrc
    echo 'export GST_PLUGIN_PATH="/opt/build/dist/darwin_x86_64/lib:$GST_PLUGIN_PATH"' >> ~/.zshrc
    echo 'export PKG_CONFIG_PATH="/opt/build/dist/darwin_x86_64/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.zshrc
    echo 'export GST_PLUGIN_SCANNER="/opt/build/dist/darwin_x86_64/libexec/gstreamer-1.0:$GST_PLUGIN_SCANNER"' >> ~/.zshrc

    }




### below are the Run services 
# Run Services

open_tab() {
    local cmd="$1"
    echo "====== In "$os_type" OS , running the services....."
    if [[ "$os_type" == "Darwin" ]]; then
        echo "You are running on macOS."
        osascript -e "tell application \"Terminal\" to activate"
        osascript -e "tell application \"System Events\" to tell process \"Terminal\" to keystroke \"t\" using command down"
        osascript -e "tell application \"Terminal\" to do script \"$cmd\" in selected tab of the front window"
    elif [[ "$os_type" == "Linux" ]]; then
        echo "You are running on Linux."
        gnome-terminal --tab -- bash -c "$cmd; exec bash"
    else
        echo "Unknown OS: $os_type"

    fi
}
# run_services() {
#     echo "====== Running ....."
#     # open_tab "cd $script_dir/mozark-cli/controller_software/deploy && docker-compose -f docker-compose.yml up -d"
#     open_tab "cd $script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/; . venv/bin/activate; python3 app-testing-controller-stack/controller_software/index.py --run-app --disable-live-logs"
#     open_tab "cd $script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/; . venv/bin/activate; python3 app-testing-controller-stack/controller_software/index.py --run-director --disable-live-logs"
# }

run_services() {
    echo "====== Running ....."

    if [[ $(printf '%s\n' "3.6.0" "$version" | sort -V | head -n1) == "3.6.0" ]]; then
        # version >= 3.6.0 → use .venv inside app-testing-controller-stack
        open_tab "cd $script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/; . app-testing-controller-stack/.venv/bin/activate; python3 app-testing-controller-stack/controller_software/index.py --run-app --disable-live-logs"
        open_tab "cd $script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/; . app-testing-controller-stack/.venv/bin/activate; python3 app-testing-controller-stack/controller_software/index.py --run-director --disable-live-logs"
    else
        # version < 3.6.0 → use venv at project root
        open_tab "cd $script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/; . venv/bin/activate; python3 app-testing-controller-stack/controller_software/index.py --run-app --disable-live-logs"
        open_tab "cd $script_dir/deployment/$cli_tag/mozark-cli-$cli_tag/; . venv/bin/activate; python3 app-testing-controller-stack/controller_software/index.py --run-director --disable-live-logs"
    fi
}

for_fresh_mac() {
   echo "Started installing in "$os_type" "
#    for ((i=0; i<${#tools[@]}; i++)); do
#         check_and_install "${tools[i]}" "${commands[i]}"
#     done

    for i in "${!tools[@]}"; do
        check_and_reinstall "${tools[$i]}" "${install_cmds[$i]}" "${cleanup_cmds[$i]}"
    done
    install_goios  
}

for_fresh_linux() {
    echo "Started installing in "$os_type" "
    # linux_gst_stream_binary
    # scrcpymz_binary_linux
}

for_update_version() {
    if [[ "$os_type" == "Darwin" ]]; then
        echo "You are running on macOS."
        
        mac_mozark_cli_package
    elif [[ "$os_type" == "Linux" ]]; then
        echo "You are running on Linux."
        linux_mozark_cli_package
    else
        echo "Unknown OS: $os_type"

    fi
    if [[ $(printf '%s\n' "3.6.0" "$version" | sort -V | head -n1) == "3.6.0" ]]; then
        cd "$script_dir/deployment/$cli_tag/mozark-cli-$cli_tag" || exit 1
        . app-testing-controller-stack/.venv/bin/activate
    else
        cd "$script_dir/deployment/$cli_tag/mozark-cli-$cli_tag" || exit 1
        . venv/bin/activate
    fi

    device_status=$(tag_upgreader "$cli_tag" "$binaries")
    rm -f "$TAG_UPGREADER_SCRIPT"
    echo "===== installation Done Successfully ====="
    }



display_help() {
    echo "help: Check below OPTIONS and COMMANDS."
    echo "  MOZARK CLI version: $cli_tag"
    echo ""
    echo "  USAGE: ./mozark-cli [OPTIONS] -c [COMMANDS]"
    echo ""
    echo "  OPTION/Commands:"
    echo "      --version : For checking version"
    echo "      install -c enroll: For Fresh installing controller-stack (here need COMMANDS)"
    echo "      install -c update: For Fresh installing controller-stack (here need COMMANDS)"
    echo "      invoke_service : For running services (here need COMMANDS)"
    echo "      --bluetooth_id : For getting bluetooth_id (here need COMMANDS)"
    echo "      --webcam_id : For getting webcam_id (here need COMMANDS)"

    echo ""
    echo "  EXAMPLE:"
    echo "      version"
    echo "          ./mozark-cli.sh --version"
    echo "      install fresh"
    echo "          ./mozark-cli.sh install -c enroll"
    echo "      install update"
    echo "          ./mozark-cli.sh install -c update"
    echo "      run"
    echo "         cd ~/{tenant} && ./mozark-cli.sh invoke_service"
    echo "         OR"
    echo "         cd ~/{tenant} && ./mozark-cli.sh run"
    echo "      bluetooth_id"
    echo "         cd ~/{tenant} && ./mozark-cli.sh bluetooth_id"
    echo "      webcam_id"
    echo "         cd ~/{tenant} && ./mozark-cli.sh webcam_id"
    echo "      audio_id"
    echo "         cd ~/{tenant} && ./mozark-cli.sh audio_id"
    echo "      devices"
    echo "         cd ~/{tenant} && ./mozark-cli.sh device_status"
    echo "      services"
    echo "         cd ~/{tenant} && ./mozark-cli.sh service_status"
    echo "      For self upgrade mozark-cli.sh script"
    echo "         cd ~/{tenant} && ./mozark-cli.sh self-upgrade"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

terminate_and_close() {
    local process_name="$1"
    echo "🔍 Looking for: $process_name"

    pids=$(pgrep -f "$process_name")
    if [ -z "$pids" ]; then
        echo "⚠️ No running process found for $process_name"
        return
    fi

    for pid in $pids; do
        echo "✅ Found PID $pid for $process_name"
        tty=$(ps -o tty= -p "$pid" | tr -d ' ')
        echo "🖥️ Associated tty: $tty"

        kill "$pid"
        echo "🛑 Killed process $pid"
        sleep 1

        osascript <<EOF
        tell application "Terminal"
            repeat with w in windows
                repeat with t in tabs of w
                    if tty of t contains "$tty" then
                        close w
                        exit repeat
                    end if
                end repeat
            end repeat
        end tell
EOF
    done
}


autokillstart() {
    local base_path="$1"
    local env_path="$2"
    local script_path="$3"
    log "✅ Services terminated."
    terminate_and_close "index.py --run-app"
    terminate_and_close "index.py --run-director"
    echo "✅ Services terminated. Restarting..."

    # Commands
    CMD_DIRECTOR="cd $base_path; source $venv_path; python3 $script_path --run-director --disable-live-logs"
    CMD_RUN_APP="cd $base_path; source $venv_path; python3 $script_path --run-app --disable-live-logs"

    ESCAPED_CMD_DIRECTOR=$(echo "$CMD_DIRECTOR" | sed 's/"/\\"/g')
    ESCAPED_CMD_RUN_APP=$(echo "$CMD_RUN_APP" | sed 's/"/\\"/g')

    # Start both in Terminal tabs, use AppleScript to type creds in run-app
    osascript <<EOF
    tell application "Terminal"
        activate
        -- Tab 1: run-director
        do script "$ESCAPED_CMD_DIRECTOR"
        delay 10

        -- Tab 2: run-app
        tell application "System Events" to keystroke "t" using command down
        delay 5
        do script "$ESCAPED_CMD_RUN_APP" in selected tab of the front window

        -- Delay for app to prompt for username
        delay 20
        tell application "System Events"
            keystroke "$username"
            key code 36 -- return
            delay 1
            keystroke "$password"
            key code 36 -- return
        end tell
    end tell
EOF

    echo "🚀 Both services launched. Check Terminal tabs."

}

terminate_and_close_site24() {
    local process_name="$1"
    echo "🔍 Looking for: $process_name"

    pids=$(pgrep -f "$process_name")
    if [ -z "$pids" ]; then
        echo "⚠️ No running process found for $process_name"
        return
    fi

    for pid in $pids; do
        echo "✅ Found PID $pid for $process_name"
        tty=$(ps -o tty= -p "$pid" | tr -d ' ')
        echo "🖥️ Associated tty: $tty"

        kill "$pid"
        echo "🛑 Killed process $pid"
        sleep 1

        osascript <<EOF
        tell application "Terminal"
            repeat with w in windows
                repeat with t in tabs of w
                    if tty of t contains "$tty" then
                        close w
                        exit repeat
                    end if
                end repeat
            end repeat
        end tell
EOF
    done
}

autokillstart_site24() {
    local base_path="$1"
    local env_path="$2"
    local script_path="$3"

    local timestamp_file="/tmp/autokillstart_site24.timestamp"
    local cooldown=10  # Cooldown period in seconds

    # Check timestamp cooldown
    if [ -f "$timestamp_file" ]; then
        local last_run=$(cat "$timestamp_file")
        local now=$(date +%s)
        if (( now - last_run < cooldown )); then
            log "⏳ Recently executed within $cooldown seconds. Skipping..."
            exit 0
        fi
    fi

    # Update timestamp
    date +%s > "$timestamp_file"
    # Check if run-app is running
    pgrep -f "index.py --run-app" > /dev/null
    run_app_running=$?
    
    # Check if run-director is running
    pgrep -f "index.py --run-director" > /dev/null
    run_director_running=$?
    
    # If both are running, do nothing
    if [ $run_app_running -eq 0 ] && [ $run_director_running -eq 0 ]; then
        log "✅ Both services are already running. No action needed."
        exit 0
    fi
    
    # If any one is not running, restart both
    log "⚠️ One or both services are not running. Restarting both..."
    terminate_and_close_site24 "index.py --run-app"
    terminate_and_close_site24 "index.py --run-director"

 
    log "✅ Services terminated. Restarting..."
    
    # Commands
    CMD_DIRECTOR="cd $base_path; source $venv_path; python3 $script_path --run-director --disable-live-logs"
    CMD_RUN_APP="cd $base_path; source $venv_path; python3 $script_path --run-app --disable-live-logs"
    
    ESCAPED_CMD_DIRECTOR=$(echo "$CMD_DIRECTOR" | sed 's/"/\\"/g')
    ESCAPED_CMD_RUN_APP=$(echo "$CMD_RUN_APP" | sed 's/"/\\"/g')
    
    # Start both in Terminal tabs, use AppleScript to type creds in run-app
    osascript <<EOF
    tell application "Terminal"
        activate
        -- Tab 1: run-director
        do script "$ESCAPED_CMD_DIRECTOR"
        delay 1
    
        -- Tab 2: run-app
        tell application "System Events" to keystroke "t" using command down
        delay 5
        do script "$ESCAPED_CMD_RUN_APP" in selected tab of the front window
    
        -- Delay for app to prompt for username
        delay 30
        tell application "System Events"
            keystroke "$username"
            key code 36 -- return
            delay 2
            keystroke "$password"
            key code 36 -- return
        end tell
    end tell
EOF
    
    log "🚀 Both services launched. Check Terminal tabs."

}


self_upgrade() {

    # Download latest script to temp file
    curl -s -S --user "mozarkai-ashwin:ATBBWYS776jvNBWVahntzH8Lfw2v8E98CB66" \
        -L "https://api.bitbucket.org/2.0/repositories/mozarkai/controller-deployment/downloads/mozark-cli.sh" \
        -o "$SELF_UPGRADE_SCRIPT"
    if [ $? -ne 0 ] || [ ! -s "$SELF_UPGRADE_SCRIPT" ]; then
        echo "❌ Failed to download update"
        rm -f "$SELF_UPGRADE_SCRIPT"
        exit 1
    fi
    chmod +x "$SELF_UPGRADE_SCRIPT"
    mv "$SELF_UPGRADE_SCRIPT" "$SELF"

    echo "✅ Upgrade complete! Run again: $SELF"
    exit 0

}

if [ "$1" == "install" ] && [ "$2" == "-c" ] && [ "$3" == "fresh" ]; then
    echo "====== In "$os_type" OS , checking and Installing tools for fresh installation....."
    if [[ "$os_type" == "Darwin" ]]; then
        echo "You are running on macOS."
        for_fresh_mac
    elif [[ "$os_type" == "Linux" ]]; then
        echo "You are running on Linux."
        for_fresh_linux
    else
        echo "Unknown OS: $os_type"

    fi
    for_update_version
    echo "===== installtion Done Successfully====="
    # live_logs

elif [ "$1" == "install" ] && [ "$2" == "-c" ] && [ "$3" == "update" ]; then
echo "====== In "$os_type" OS , Updating controller stack version....."
    for_update_version
    echo "===== version updated Successfully====="

elif [ "$1" == "invoke_service" ]; then
    echo "====== Running ....."
    shift
    run_services "$@"

elif [ "$1" == "run" ]; then
    echo "====== Running ..... [$(date '+%Y-%m-%d %H:%M:%S')]"
    shift
    run_services "$@"

elif [ "$1" == "--version" ]; then
    echo "versions : MOZARK CLI: $cli_tag"

elif [ "$1" == "--help" ]; then
    display_help

elif [ "$1" == "bluetooth_id" ]; then
    bluetooth_id
    rm "$BLUETOOTH_SCRIPT"
elif [ "$1" == "webcam_id" ]; then
    webcam_id
    rm "$WEBCAM_SCRIPT"
elif [ "$1" == "audio_id" ]; then
    audio_id
    rm "$AUDIO_SCRIPT"
elif [ "$1" == "device_status" ]; then
    check_devices_status
    rm "$MONGO_SCRIPT"
elif [ "$1" == "service_status" ]; then
    check_services "$SERVICE_APP" "$SERVICE_DIRECTOR"
elif [ "$1" == "autokillstart" ]; then
    autokillstart "$base_path" "$env_path" "$script_path"
elif [ "$1" == "autokillstart_site24" ]; then
    autokillstart_site24 "$base_path" "$env_path" "$script_path"
elif [ "$1" == "self-upgrade" ]; then
    self_upgrade
else
    display_help

    exit 1
fi


# cd ~/{tenant} && ./mozark-cli.sh run

