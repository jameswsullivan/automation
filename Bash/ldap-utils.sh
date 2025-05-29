# Install ldap-utils:
apt-get install ldap-utils -y

# Sample query:
ldapsearch -x -H ldaps://myldap.server.com \
-D "CN=<CN> <admin_account>,OU=<OU>,DC=<DC>,DC=<DC>,DC=com" \
-w 'mypassword' -b "DC=<DC>,DC=<DC>,DC=com" "(sAMAccountName=<username>)"

# Don't require cert:
LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://myldap.server.com \
-D "CN=<CN> <admin_account>,OU=<OU>,DC=<DC>,DC=<DC>,DC=com" \
-w 'mypassword' -b "DC=<DC>,DC=<DC>,DC=com" "(sAMAccountName=<username>)"

