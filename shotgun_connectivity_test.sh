#!/usr/bin/env bash

# Globals
sg_lbs_ip=('74.50.63.109' '74.50.63.111')
sg_cdnetwork_cname=('wildcard-geo.shotgunstudio.com' 'wildcard-cdn.shotgunstudio.com.')

# S3
s3_oregon=sg-media-usor-01.s3.amazonaws.com
s3_tokyo=sg-media-tokyo.s3.amazonaws.com
s3_ireland=sg-media-ireland.s3.amazonaws.com
s3=($s3_oregon $s3_tokyo $s3_ireland)

s3a_oregon=sg-media-usor-01.s3.amazonaws.com
s3a_tokyo=sg-media-tokyo.s3.amazonaws.com
s3a_ireland=sg-media-ireland.s3.amazonaws.com
s3a=($s3a_oregon $s3a_tokyo $s3a_ireland)

# Test funciton header
function test_header {
    title=$1
    echo
    echo "#####"
    echo "# $title"
    echo "#####"
}

# Simply ping google dns to get a feel of network latency.
function ping_benchmark {
    test_header "Pinging google dns to get a feel of network latency..."
    ping -c 5 8.8.8.8
}

# Run speedtest to get network speed.
function speedtest {
    test_header "Running speedtest to test network speed"

    # Python?
    python_version="$(python --version 2>&1)"
    substring="Python"
    if [[ "$python_version" == *"Python"* ]]; then
        echo "Python is installed."
        speedtest_exec
    else
        echo "No Python detected. Skipping speedtest."
    fi
}

function speedtest_exec {
    # Try to get latest version
    echo "Trying to fetch latest version of speedtest-cli..."
    curl --fail https://rw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py -o "speedtest_latest.py"
    if [ $? == 0 ]
    then
        echo "... Success! Using latest version."
        chmod +x speedtest_latest.py
        ./speedtest_latest.py
        rm speedtest_latest.py
    else
        echo "... Couldn't get latest version; using cached version."
        # Run cached version
        rm speedtest_latest.py
        ./speedtest.py
    fi
}

# Test connectivity to given end-point
function test_endpoint {
    endpoint=$1
    ping -c 10 $endpoint
    traceroute -w 3 -q 1 -m 15 $endpoint
}

# Test connectivity to Shotgun Load Balancers
function test_lbs {
    for i in ${sg_lbs_ip[@]}; do
        test_header "Testing connectivity to Shotgun Load Balancer at $i"
        test_endpoint $i
    done
}

# Test connectivity to Shotgun through CDNetworks
function test_cdnetworks {
    for i in ${sg_cdnetwork_cname[@]}; do
        test_header "Testing connectivity to Shotgun through CDNetworks: $i"
        test_endpoint $i
    done
}

# Test connectivity to Shotgun S3 Buckets
function test_s3 {
    for i in ${s3[@]}; do
        test_header "Testing connectivity to Shotgun S3 Bucket: $i"
        test_endpoint $i
    done
}

# Test connectivity to Shotgun S3 Buckets
function test_s3_accel {
    for i in ${s3a[@]}; do
        test_header "Testing connectivity to Shotgun S3 Bucket: $i"
        test_endpoint $i
    done
}

# Usage function
function showUsage {
    echo "Usage: bash shotgun_connectivity_test.sh [options]"
    echo "Test connectivity to the Shotgun end-points."
    echo -e "\t[--all]               Test connectivity to all end-points. Default."
    echo -e "\t[--cdn]               Test connectivity to Shotgun Geolocated Network Accelerator (CDNetworks)."
    echo -e "\t[--lb]                Test connectivity to Shotgun load balancers."
    echo -e "\t[--s3]                Test connectivity to Shotgun S3 Buckets."
    echo -e "\t[--s3a]               Test connectivity to Shotgun S3 Accelerated Transfer Buckets."
    echo -e "\t[--speedtest          Run speedtest."
    echo -e "\t[--geo_oregon]        Spefically test for the oregon geo."
    echo -e "\t[--geo_tokyo]         Spefically test for the tokyo geo."
    echo -e "\t[--geo_ireland]       Spefically test for the ireland geo."
    echo -e "\t[-h,--help,--usage]   Display help and exit."
    echo -e "\t[-v,--verbose]        Print commands before executing them."
}

# Parse command-line options
if [ $# -eq 0 ]; then
    showUsage
    exit 0
fi

for i in "$@"
do
case $i in
-v|--verbose)
    set -x
    shift
    ;;
-h|-help|--usage|--help)
    showUsage
    exit 0
    ;;
--geo_oregon)
    s3=$s3_oregon
    s3a=$s3a_oregon
    shift
    ;;
--geo_ireland)
    s3=$s3_ireland
    s3a=$s3a_ireland
    shift
    ;;
--geo_tokyo)
    s3=$s3_tokyo
    s3a=$s3a_tokyo
    shift
    ;;
--lb)
    do_test_lbs=1
    shift
    ;;
--s3)
    do_test_s3=1
    shift
    ;;
--s3)
    do_test_s3a=1
    shift
    ;;
--cdn)
    do_test_cdnetworks=1
    shift
    ;;
--speedtest)
    do_speedtest=1
    shift
    ;;
--all)
    do_speedtest=1
    do_test_lbs=1
    do_test_cdnetworks=1
    do_test_s3=1
    do_test_s3a=1
    shift
    ;;
*)
    ;;
esac
done

# Always ping google for a benchmark
ping_benchmark

if [ -n "$do_speedtest" ]; then
    speedtest
fi

if [ -n "$do_test_lbs" ]; then
    test_s3
fi

if [ -n "$do_test_cdnetworks" ]; then
    test_cdnetworks
fi

if [ -n "$do_test_s3" ]; then
    test_s3
fi

if [ -n "$test_s3a" ]; then
    test_s3_accel
fi

exit 0