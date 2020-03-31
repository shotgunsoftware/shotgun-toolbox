#!/usr/bin/env bash
# Bash script that run multiple tests to access the state of the Shotgun service.
# Linux and MacOS support only.

# Globals
# Warning: These IPs are subject to change.
sg_lbs_ip=('74.50.63.109' '74.50.63.111', '13.248.152.42', '76.223.30.16')
sg_cdnetwork_cname=('wildcard-geo.shotgunstudio.com' 'wildcard-cdn.shotgunstudio.com.')
sg_cdnetwork_cname_no_ping=('wildcard-origin-cloud.shotgunstudio.com')

skip_traceroute=0

# S3
s3_oregon=sg-media-usor-01.s3.amazonaws.com
s3_tokyo=sg-media-tokyo.s3.amazonaws.com
s3_ireland=sg-media-ireland.s3.amazonaws.com
s3_mumbai=sg-media-mumbai.s3.amazonaws.com
s3_saopaulo=sg-media-saopaulo.s3.amazonaws.com
s3_sydney=sg-media-sydney.s3.amazonaws.com
s3=($s3_oregon $s3_tokyo $s3_ireland $s3_mumbai $s3_saopaulo $s3_sydney)

s3a_oregon=sg-media-usor-01.s3-accelerate.amazonaws.com
s3a_tokyo=sg-media-tokyo.s3-accelerate.amazonaws.com
s3a_ireland=sg-media-ireland.s3-accelerate.amazonaws.com
s3a_mumbai=sg-media-mumbai.s3-accelerate.amazonaws.com
s3a_saopaulo=sg-media-saopaulo.s3-accelerate.amazonaws.com
s3a_sydney=sg-media-sydney.s3-accelerate.amazonaws.com
s3a=($s3a_oregon $s3a_tokyo $s3a_ireland $s3a_mumbai $s3a_saopaulo $s3a_sydney)

# Test funciton header
function test_header {
    title=$1
    echo
    echo "################################################################"
    echo "# $title"
    echo "################################################################"
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
        echo "INFO: Python is installed."
        speedtest_exec
    else
        echo "INFO: No Python detected. Skipping speedtest."
    fi
}

# Execute speedtest using latest version of speedtest-cli. Fall-back on cached version on failure.
function speedtest_exec {
    # Try to get latest version
    echo "INFO: Trying to fetch latest version of speedtest-cli..."
    curl --fail https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py -o "speedtest_latest.py"
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
    no_ping=$2

    if ! [ $no_ping == 1 ]; then
        ping -c 10 $endpoint
    elif type "telnet" > /dev/null; then
        telnet $1 80
    elif type "nc" > /dev/null; then
        nc -vz $1 80
    else
        echo "Please install/enable telnet or netcat to test connectivity to $1"
    fi

    if [ $skip_traceroute == 0 ]; then
        traceroute -w 3 -q 1 -m 15 $endpoint
    fi
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

    for i in ${sg_cdnetwork_cname_no_ping[@]}; do
        test_header "Testing connectivity to Shotgun through CDNetworks: $i"
        test_endpoint $i 1
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
    echo "When invoked with no options, default to:"
    echo "    bash shotgun_connectivity_test.sh --all"
    echo -e "\t[--short]             Default. Test connectivity to all end-points"
    echo -e "\t[--all]               Test connectivity to all end-points in depth, executing traceroutes to all end-points."
    echo -e "\t[--cdn]               Test connectivity to Shotgun Web Acceleration Service (CDNetworks)."
    echo -e "\t[--lb]                Test connectivity to Shotgun load balancers."
    echo -e "\t[--s3]                Test connectivity to Shotgun S3 Buckets."
    echo -e "\t[--s3a]               Test connectivity to Shotgun S3 Accelerated Transfer Buckets."
    echo -e "\t[--speedtest]         Run speedtest."
    echo -e "\t[--geo_oregon]        Test connectivity to the oregon geo."
    echo -e "\t[--geo_tokyo]         Test connectivity to the tokyo geo."
    echo -e "\t[--geo_ireland]       Test connectivity to the ireland geo."
    echo -e "\t[--geo_saopaulo]      Test connectivity to the saopaulo geo."
    echo -e "\t[-h,--help,--usage]   Display help."
    echo -e "\t[-v,--verbose]        Print commands before executing them."
}

# Activate all tests
function activate_all_tests {
    do_speedtest=1
    do_test_lbs=1
    do_test_cdnetworks=1
    do_test_s3=1
    do_test_s3a=1
}

# Parse command-line options
if [ $# -eq 0 ]; then
    activate_all_tests
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
--geo_saopaulo)
    s3=$s3_saopaulo
    s3a=$s3a_saopaulo
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
--s3a)
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
--short)
    echo "INFO: Short mode activated. Skipping trace routes."
    skip_traceroute=1
    shift
    ;;
--all)
    activate_all_tests
    shift
    ;;
*)
    echo "Invalid parameter $i. Aborting"
    exit 1
    ;;
esac
done

# Always ping google for a benchmark
ping_benchmark

if [ -n "$do_speedtest" ]; then
    speedtest
fi

if [ -n "$do_test_lbs" ]; then
    test_lbs
fi

if [ -n "$do_test_cdnetworks" ]; then
    test_cdnetworks
fi

if [ -n "$do_test_s3" ]; then
    test_s3
fi

if [ -n "$do_test_s3a" ]; then
    test_s3_accel
fi

exit 0
