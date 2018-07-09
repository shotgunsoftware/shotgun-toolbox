# shotgun-toolbox
This repository contains various tools that can be useful for Hosted Shotgun Administrators. To use, just clone this
repository and follow the instructions.

## Testing connectivity to Shotgun Hosted Service

### Mac and Linux
`shotgun_connectivity_test.sh` will run an set of tests that will help Shotgun Support team troubleshoot networking
and connectivity issues. For help, run:

    bash shotgun_connectivity_test.sh --help
    
#### Most common configurations
If you want to diagnose the connectivity to the Shotgun Service end-points only, use the following configuration:

    bash shotgun_connectivity_test.sh --speedtest --lb --cdn

If you want to diagnose only the connectivity to S3, use the following configuration:

    bash shotgun_connectivity_test.sh --speedtest --s3 --s3a
    
You can also specify the location of your S3 media, if you know it.

    bash shotgun_connectivity_test.sh --speedtest --s3 --s3a --geo_tokyo

### Windows
*Special thanks to [Adric Worley](https://github.com/AdricEpic) (Epic Games, Inc.) for contributing the initial release of this Windows port.*
`shotgun_connectivity_test_win.py` will run an set of tests that will help Shotgun Support team troubleshoot networking
and connectivity issues. Python 2.7 is required and should be included in the %PATH% environment variable. For help, run:

    python shotgun_connectivity_test_win.py --help

#### Most common configurations
If you want to diagnose the connectivity to the Shotgun Service end-points only, use the following configuration:

    python shotgun_connectivity_test_win.py --speedtest --lb --cdn

If you want to diagnose only the connectivity to S3, use the following configuration:

    python shotgun_connectivity_test_win.py --speedtest --s3 --s3a

You can also specify the location of your S3 media, if you know it.

    python shotgun_connectivity_test_win.py --speedtest --s3 --s3a --geo_tokyo
