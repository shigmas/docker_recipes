# If we need to run without X
# Note: Quite a bit has happened for Qt on embedded, so I don't know if this
# works.
PACKAGECONFIG_append = " accessibility eglfs fontconfig gles2 linuxfb tslib"

DEPENDS += "userland"
