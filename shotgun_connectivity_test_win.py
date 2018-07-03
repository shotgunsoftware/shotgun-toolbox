# Python script that run multiple tests to access the state of the Shotgun service.
import logging as log
import os
import sys
import urllib2

from argparse import ArgumentParser
from subprocess import Popen, PIPE, STDOUT

report_path = "shotgun_connectivity_report.txt"
if os.path.exists(report_path):
    try:
        os.remove(report_path)
    except OSError:
        pass

log.basicConfig(level=log.INFO, format="%(message)s",
                filename=report_path)
stream_handler = log.StreamHandler()
stream_handler.setFormatter(log.Formatter("%(message)s"))
log.getLogger().addHandler(stream_handler)

# Globals
# Warning: These IPs are subject to change.
sg_lbs_ip = ['74.50.63.109', '74.50.63.111']
sg_cdnetwork_cnames = ['wildcard-geo.shotgunstudio.com', 'wildcard-cdn.shotgunstudio.com.']

skip_tracetoute = False

# S3
s3_oregon = "sg-media-usor-01.s3.amazonaws.com"
s3_tokyo = "sg-media-tokyo.s3.amazonaws.com"
s3_ireland = "sg-media-ireland.s3.amazonaws.com"
s3_saopaulo = "sg-media-saopaulo.s3.amazonaws.com"
s3 = [s3_oregon, s3_tokyo, s3_ireland, s3_saopaulo]

s3a_oregon = "sg-media-usor-01.s3-accelerate.amazonaws.com"
s3a_tokyo = "sg-media-tokyo.s3-accelerate.amazonaws.com"
s3a_ireland = "sg-media-ireland.s3-accelerate.amazonaws.com"
s3a_saopaulo = "sg-media-saopaulo.s3-accelerate.amazonaws.com"
s3a = [s3a_oregon, s3a_tokyo, s3a_ireland, s3a_saopaulo]


def print_header(title):
    log.info("#"*64)
    log.info(title)
    log.info("#" * 64)


def run_subprocess(*args):
    args = list(args)
    proc = Popen(args, stdout=PIPE, stderr=STDOUT)
    for stdout_line in iter(proc.stdout.readline, ""):
        log.info(stdout_line.rstrip("\n\r"))
    proc.stdout.close()


def ping_benchmark():
    # -c for *nix == -n for windows
    run_subprocess("ping", "-n", "5", "8.8.8.8")


def test_endpoint(endpoint):
    run_subprocess("ping", "-n", "10", endpoint)

    if not skip_tracetoute:
        # traceroute -w 3 -q 1 -m 15 $endpoint
        # -w : same for Windows
        # -q : no Windows equivalent
        # -m : looks like -h is closest windows equivalent
        run_subprocess("tracert", "-w", "3", "-h", "15", endpoint)


def test_speed():
    print_header("Running SpeedTest to test network speed")
    log.info("Detecting installed Python version")
    if os.system("python --version") > 0:
        log.warning("WARNING: Python environment not detected. Skipping speed test...")
        return

    log.info("Trying to fetch latest version of speedtest-cli...")
    req = urllib2.Request("https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py")
    try:
        response = urllib2.urlopen(req)
    except urllib2.HTTPError, e:
        log.error("ERROR: Could not get latest version of speedtest-cli: {}".format(e))
    else:
        if response.getcode() == 200:
            temp_script = "speedtest_latest.py"
            try:
                with open(temp_script, "w") as speedtest_file:
                    speedtest_file.write(response.read())
            except OSError:
                log.error("ERROR: Could not create temporary speedtest-cli script file")
            else:
                run_subprocess("python", temp_script)
                os.remove(temp_script)
        else:
            log.error("ERROR: speedtest-cli download failed with HTTP error code {}".format(response.getcode))


def test_lbs():
    for ip in sg_lbs_ip:
        print_header("Testing connectivity to Shotgun Load Balancer at {}".format(ip))
        test_endpoint(ip)


def test_cdnetworks():
    for cname in sg_cdnetwork_cnames:
        print_header("Testing connectivity to Shotgun through CDNetworks: {}".format(cname))
        test_endpoint(cname)


def test_s3():
    for s3_addr in s3:
        print_header("Testing connectivity to Shotgun S3 Bucket: {}".format(s3_addr))
        test_endpoint(s3_addr)


def test_s3_accel():
    for s3_addr in s3a:
        print_header("Testing connectivity to Shotgun S3 Bucket: {}".format(s3_addr))
        test_endpoint(s3_addr)


def run_tests(do_lbs, do_cdnetworks, do_s3, do_s3a, do_speedtest):
    if do_lbs:
        test_lbs()
    if do_cdnetworks:
        test_cdnetworks()
    if do_s3:
        test_s3()
    if do_s3a:
        test_s3_accel()
    if do_speedtest:
        test_speed()
    log.info("Connectivity report located at: {}".format(os.path.abspath(report_path)))


if __name__ == '__main__':
    parser = ArgumentParser(description="Test connectivity to the Shotgun end-points.\n"
                                        "When invoked with no options, default to:\n"
                                        "\tshotgun_connectivity_test_win.py --all\n")
    parser.add_argument("--short", help="Default. Test connectivity to all end-points.",
                        action="store_true")
    parser.add_argument("--all", help="Test connectivity to all end-points in depth; executes traceroutes to all end-points.",
                        action="store_true")
    parser.add_argument("--cdn", help="Test connectivity to Shotgun Web Acceleration Service (CDNetworks).",
                        action="store_true")
    parser.add_argument("--lb", help="Test connectivity to Shotgun load balancers.",
                        action="store_true")
    parser.add_argument("--s3", help="Test connectivity to Shotgun S3 Buckets.",
                        action="store_true")
    parser.add_argument("--s3a", help="Test connectivity to Shotgun S3 Accelerated Transfer Buckets.",
                        action="store_true")
    parser.add_argument("--speedtest", help="Run SpeedTest.",
                        action="store_true")

    geo_locs = parser.add_mutually_exclusive_group()
    geo_locs.add_argument("--geo_oregon", help="Spefically test for the oregon geo.", action="store_true")
    geo_locs.add_argument("--geo_tokyo", help="Spefically test for the tokyo geo.", action="store_true")
    geo_locs.add_argument("--geo_ireland", help="Spefically test for the ireland geo.", action="store_true")
    geo_locs.add_argument("--geo_saopaulo", help="Spefically test for the saopaulo geo.", action="store_true")

    parser.add_argument("-v,--verbose", help="Print commands before executing them.", action="count")

    cmd_args = parser.parse_args()
    # Run all tests if no args or only --short is provided, or if --all is enabled
    if (len(sys.argv) <= 1) or (len(sys.argv) == 2 and cmd_args.short) or cmd_args.all:
        cmd_args.speedtest = True
        cmd_args.lb = True
        cmd_args.cdn = True
        cmd_args.s3 = True
        cmd_args.s3a = True

    skip_tracetoute = cmd_args.short

    if cmd_args.geo_oregon:
        s3 = s3_oregon
        s3a = s3a_oregon
    elif cmd_args.geo_tokyo:
        s3 = s3_tokyo
        s3a = s3a_tokyo
    elif cmd_args.geo_ireland:
        s3 = s3_ireland
        s3a = s3a_ireland
    elif cmd_args.geo_saopaulo:
        s3 = s3_saopaulo
        s3a = s3a_saopaulo

    run_tests(cmd_args.lb, cmd_args.cdn, cmd_args.s3, cmd_args.s3a, cmd_args.speedtest)
