#!/bin/python

import sys
import json
import os
import re
import ast
# This file can be downloaded from the wiki-scripts repository
# https://raw.githubusercontent.com/analogdevicesinc/wiki-scripts/refs/heads/main/utils/cloudsmith_utils/cloudsmith_helper.py
from cloudsmith_helper import *

TGREEN =  '\033[32m' # Green Text
TYELLOW = '\033[33m'  # Yellow Text
TRED =  '\033[31m' # Red Text
TWHITE = '\033[39m' # White text
LOG_START = " -> "

def log(msg):
    print(TGREEN + LOG_START + TWHITE + msg)

def log_warn(msg):
    print(TYELLOW + LOG_START + msg + TWHITE)

def log_err(msg):
    print(TRED + LOG_START + msg + TWHITE)

log("download_files: starting")
log("download_files: argv=%s" % sys.argv)

api_key = os.environ.get('CLOUDSMITH_API_KEY')
log("download_files: CLOUDSMITH_API_KEY=%s" % ("set (%d chars)" % len(api_key) if api_key else "NOT SET"))

NOOS_PATH = sys.argv[1]
BUILD_PATH = sys.argv[2]
HDL_SERVER_BASE_PATH = sys.argv[3]
blacklist = ast.literal_eval(sys.argv[4])
NEW_HW_DIR_NAME = 'new_hardware'
FOLDERS_NR = 30 #number of folders to check for missing hardware file

log("download_files: NOOS_PATH=%s" % NOOS_PATH)
log("download_files: BUILD_PATH=%s" % BUILD_PATH)
log("download_files: HDL_SERVER_BASE_PATH=%s" % HDL_SERVER_BASE_PATH)
log("download_files: blacklist=%s" % blacklist)

list_hardware = []
for dir in os.listdir(NOOS_PATH + '/projects'):
    file = NOOS_PATH + '/projects/' + str(dir) + '/builds.json'
    if os.path.exists(file):
        with open(file) as f:
            data = json.load(f)
        for (platform, config) in data.items():
            for (build_name, params) in config.items():
                if 'hardware' in params:
                    for hardware_value in params['hardware']:
                        list_hardware.append(hardware_value)

log("download_files: found %d total hardware entries from builds.json files" % len(list_hardware))

new_harware_dir= os.path.join(BUILD_PATH, NEW_HW_DIR_NAME)
log("download_files: new_hardware_dir=%s" % new_harware_dir)
os.system("rm -rf %s/*" % (new_harware_dir))
unique_hardware_list = set(list_hardware)
log("download_files: %d unique hardware entries before blacklist removal" % len(unique_hardware_list))
for item in blacklist:
    if item in unique_hardware_list:
        log("download_files: removing blacklisted hardware: %s" % item)
        unique_hardware_list.remove(item)
log("download_files: %d unique hardware entries after blacklist removal: %s" % (len(unique_hardware_list), sorted(unique_hardware_list)))
pattern= '\d{4}_\d{2}_\d{2}-\d{2}_\d{2}_\d{2}'
timestamp_match = re.search(pattern, HDL_SERVER_BASE_PATH)
log("download_files: timestamp_match=%s in HDL_SERVER_BASE_PATH=%s" % (timestamp_match.group() if timestamp_match else "None", HDL_SERVER_BASE_PATH))

if timestamp_match:
    log("download_files: using specific timestamp mode")
    for hardware in unique_hardware_list:
        file_path = HDL_SERVER_BASE_PATH + hardware + '/'
        log("download_files: checking file_path=%s for system_top.xsa" % file_path)
        files = get_files(package_version=file_path, repo='sdg-hdl')
        log("download_files: get_files returned: %s" % files)
        if 'system_top.xsa' in files:
            log("download_files: downloading system_top.xsa for %s" % hardware)
            os.system("mkdir -p %s" % (str(new_harware_dir) + '/' + hardware))
            get_artifacts_from_location(package_version=file_path, package_name= 'system_top.xsa', repo='sdg-hdl')
            os.system("mv ./system_top.xsa %s" % (str(new_harware_dir) + '/' + hardware))
            log("download_files: downloaded %s successfully" % hardware)
        else:
            log_warn("Missing " + hardware + " from specific timestamp " + timestamp_match.group())
else:
    log("download_files: using latest-timestamp mode, querying subfolders from hdl/main/hdl_output/")
    timestamp_folders = get_subfolders(package_version='hdl/main/hdl_output/', repo='sdg-hdl')
    log("download_files: got %d timestamp folders" % len(timestamp_folders))
    timestamp_folders = (timestamp_folders[len(timestamp_folders) - FOLDERS_NR:])
    timestamp_folders.reverse()
    latest = timestamp_folders[0]
    release_link = HDL_SERVER_BASE_PATH + latest + "/"
    log("download_files: latest timestamp=%s, release_link=%s" % (latest, release_link))

    for hardware in unique_hardware_list:
        FOUND = False
        file_path = release_link + hardware + "/"
        log("download_files: checking %s at %s" % (hardware, file_path))
        files = get_files(package_version=file_path, repo='sdg-hdl')
        log("download_files: get_files for %s returned: %s" % (hardware, files))
        if 'system_top.xsa' in files:
            log("download_files: downloading system_top.xsa for %s from latest" % hardware)
            os.system("mkdir -p %s" % (str(new_harware_dir) + '/' + hardware))
            get_artifacts_from_location(package_version=file_path, package_name= 'system_top.xsa', repo='sdg-hdl')
            os.system("mv ./system_top.xsa %s" % (str(new_harware_dir) + '/' + hardware))
            FOUND = True
            log("download_files: downloaded %s successfully from latest" % hardware)
        else:
            log_warn("Missing " + hardware + " from latest timestamp " + latest)
            log("download_files: searching older timestamps for %s" % hardware)
            for timestamp_folder in timestamp_folders[1:]:
                d_path = HDL_SERVER_BASE_PATH + timestamp_folder + "/" + hardware + "/"
                log("download_files: trying %s at %s" % (hardware, d_path))
                if 'system_top.xsa' in get_files(package_version=d_path, repo='sdg-hdl'):
                    log("download_files: found %s at timestamp %s" % (hardware, timestamp_folder))
                    os.system("mkdir -p %s" % (str(new_harware_dir) + '/' + hardware))
                    get_artifacts_from_location(package_version=d_path, package_name= 'system_top.xsa', repo='sdg-hdl')
                    os.system("mv ./system_top.xsa %s" % (str(new_harware_dir) + '/' + hardware))
                    file_properties = get_item_properties(package_version=d_path, package_name= 'system_top.xsa', repo='sdg-hdl')
                    if file_properties and len(file_properties) >= 2:
                        commit_date = file_properties[0].split('-', 1)[1]
                        git_sha = file_properties[1].split('-', 1)[1]
                        log_warn("Hardware " + hardware + " found on next timestamp " + timestamp_folder + " with next properties git sha: " + \
                            str(git_sha) + " commit date: " + str(commit_date))
                    else:
                        log_warn("Hardware " + hardware + " found on next timestamp " + timestamp_folder)
                    FOUND = True
                    break
        if FOUND is False:
            log_err("download_files: hardware %s was NOT found on server in any timestamp" % hardware)

log("download_files: finished")
