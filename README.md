# shotgun-toolbox
This repository contains various tools that can be useful for Hosted Shotgun Administrators. To use, just clone this
repository and follow the instructions.

## Testing connectivity to Shotgun Hosted Service
`shotgun_connectivity_test.sh` will run an set of test that will help Shotgun Support team troubleshoot networking
and connectivity issues. For help, run:

    bash shotgun_connectivity_test.sh --help
    
**Only Mac and Unix is supported.**
    
### Most common configurations
If you want to diagnose the connectivity to the Shotgun Service end-points only, use the following configuration:

    bash shotgun_connectivity_test.sh --speedtest --lb --cdn

If you want to diagnose only the connectivity to S3, use the following configuration:

    bash shotgun_connectivity_test.sh --speedtest --s3 --s3a
    
You can also specify the location of your S3 media, if you know it.

    bash shotgun_connectivity_test.sh --speedtest --s3 --s3a --geo_tokyo
    