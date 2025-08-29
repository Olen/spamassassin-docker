# SpamAssassin

A slightly modified SpamAssassin v4 [docker container](https://hub.docker.com/r/axllent/spamassassin)
running on Alpine Linux.

My modifications mostly involves adding more spamassassin plugins and adding labels to the container 
image

This image is designed to listen on port 783 for third-party integration, and is not a full-featured
spam solution. It was created primarily for integration with [Mailpit](https://mailpit.axllent.org).

By default all DNS checks including rDNS (reverse DNS) are disabled to vastly improve performance and 
account for local testing, however all DNS checks (including rDNS) can be enabled by adding the 
`DNS_CHECKS=1` environment variable.

Spam rules are automatically updated daily and on startup.

The shell-script `build.sh` can be used to build the image, but will need some local tweaks to handle
pushing to container registry etc.
