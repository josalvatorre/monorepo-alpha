# This debug image will be the same as the original image but with a shell
# and a few other utilities.
FROM busybox:1.36.1-uclibc as busybox

INCLUDE+ Dockerfile

COPY --from=busybox /bin/sh /bin/sh
COPY --from=busybox /bin/cat /bin/cat

ENTRYPOINT ["/bin/sh"]
