# krb5-docker

A container image to run MIT Kerberos 5, plus some other things that may be useful for running krb5 in a containerized environment.

### Running

One-liner to get started:

```bash
docker run -v ./data:/var/lib/krb5kdc -e KRB5_REALM=EXAMPLE.ORG -p 88:8888/tcp -p 88:8888/udp -p 464:8464/tcp -p 464:8464/udp -p 749:8749/tcp ghcr.io/authentik-community/krb5:<version>
```

On the first boot, the container will create necessary configurations and a KDC Master password and store it under `/var/lib/krb5kdc/master.pass` (in the container). You should save the contents of that file and then delete it.

#### Configuration variables

Here is the list of available environment variables:

- `KRB5_REALM`: the realm of the KDC. Required.
- `KRB5_KDC_MASTER_PASSWORD_FILE`: path to the file where the master password is stored. If that file exists, it will be used on first startup instead of generating a new master password.
- `KRB5_KDC`: optional KDC address to add to /etc/krb5.conf
- `KRB5_ADMINSERVER`: optional admin server address to add to /etc/krb5.conf
- `KRB5_KDC_PORT`: port the KDC will listen on (TCP and UDP), defaults to 8888.
- `KRB5_KPASSWD_PORT`: port kadmind will listen on for password change requests (TCP and UDP), defaults to 8464.
- `KRB5_KADMIN_PORT`: port kadmind will listen on for admin requests (TCP), defaults to 8749

Here is the list of files you can override with your own configuration:

- `/etc/krb5.conf`: standard krb5.conf. Must contain the KDC realm as the default realm.
- `/etc/krb5kdc/kdc.conf`: the KDC configuration file.
- `/var/lib/krb5kdc/kadm5.acl`: KDC ACL file. By default, it specifies that `*/admin` principals have every right. You can edit this file in place too, as it's not overwritten once it exists.

### Contributing

Just open a PR :D

### License

[AGPL-3.0-or-later](./LICENSE)
