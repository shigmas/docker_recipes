#!/bin/sh

echo "Project: $PROJECT"

MYARGS="foo $PROJECT"
echo foo ls \'$MYARGS\'

export GPG_TTY=$(tty)
gpg --import $GPG_PUB_KEY
GPG_KEY_ID=$(gpg --list-key | grep -E  ^[[:space:]]+[[:alnum:]]+$ | awk '{print $1}')
# This doesn't seem to work...
echo $GPG_PASSPHRASE | gpg --batch --allow-secret-key-import --import $GPG_PRIV_KEY

cat << EOF > ~/.gnupg/gpg.conf
default-key $GPG_KEY_ID
EOF

mkdir -p /var/www/repos/apt/debian

echo ServerName debrepo >> /etc/apache2/apache2.conf 

cat <<EOF > /etc/apache2/sites-available/repos.conf
# /etc/apache2/conf.d/repos
# Apache HTTP Server 2.4
<VirtualHost *:80>
DocumentRoot /var/www/repos

<Directory /var/www/repos/ >
        # We want the user to be able to browse the directory manually
        Options Indexes FollowSymLinks Multiviews
        Require all granted
</Directory>

# This syntax supports several repositories, e.g. one for Debian, one for Ubuntu.
# Replace * with debian, if you intend to support one distribution only.
<Directory "/var/www/repos/apt/*/db/">
        Require all denied
</Directory>

<Directory "/var/www/repos/apt/*/conf/">
        Require all denied
</Directory>

<Directory "/var/www/repos/apt/*/incoming/">
        Require all denied
</Directory>
</VirtualHost>
EOF

a2enmod ssl
a2ensite repo
a2dissite 000-default

CONF_TEST_RES=$(apache2ctl configtest 2>& 1)
if [ ! "$CONF_TEST_RES" = "Syntax OK" ] ; then
    echo "Config failed: $CONF_TEST_RES"
    exit
fi

/etc/init.d/apache2 reload

mkdir -p /var/www/repos/apt/debian/conf

# Components is key and must match the last part of the
# sudo add-apt-repository "deb [arch=amd64] http://fossa00.local/apt/debian focal main"
cat <<EOF > /var/www/repos/apt/debian/conf/distributions
Origin: $PROJECT Project
Label: $PROJECT Project
Suite: stable
Codename: buster
Architectures: i386 amd64
Components: main
Description: Apt repository for project $PROJECT
SignWith: $GPG_KEY_ID

Origin: $PROJECT Project
Label: $PROJECT Project
Suite: stable
Codename: focal
Architectures: i386 amd64
Components: main
Description: Apt repository for project $PROJECT
SignWith: $GPG_KEY_ID
EOF

cat <<EOF > /var/www/repos/apt/debian/conf/options
verbose
basedir /var/ww/repos/apt/debian
ask-passphrase
EOF

# Copy the public key so users can add it to their apt-keys
gpg --armor --output /var/www/repos/apt/debian/conf/$PROJECT.gpg.key --export $GPG_KEY_ID
