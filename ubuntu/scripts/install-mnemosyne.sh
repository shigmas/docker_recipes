#!/bin/sh

# install the prerequisites
pip3 install --upgrade pip
pip3 install --upgrade PyQt5 matplotlib cheroot webob pillow googletrans gTTS

tar xvfz Mnemosyne-2.7.3.tar.gz

cd Mnemosyne-2.7.3
python3 setup.py install

# Run it once as a sync server. This will fail with Authorization not set, but
# it will create the database
/usr/local/bin/mnemosyne --sync-server -d /mnemosyne-data &
sleep 1
pkill -P $$

cat << EOF > /tmp/creds
update config set value="'xxx'" where key = "remote_access_username";
update config set value="'yyy'" where key = "remote_access_password";
EOF

/usr/bin/sqlite3 /mnemosyne-data/config.db < /tmp/creds

