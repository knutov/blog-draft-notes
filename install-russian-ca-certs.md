# Install russian CA certs

## for Debian/Ubuntu (under root)

```bash
cd /usr/local/share/ca-certificates/

wget https://gu-st.ru/content/lending/russian_trusted_sub_ca_pem.crt
wget https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt

update-ca-certificates
```

## for RHEL/Centos (under root)

```bash
cd /usr/share/pki/ca-trust-source/anchors/

wget https://gu-st.ru/content/lending/russian_trusted_sub_ca_pem.crt
wget https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt

update-ca-trust
```

## Test if it's working

```bash
curl -I https://www.sberbank.ru
```

It will show error without correct CA certs:

```text
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

After installing certs it will show `HTTP/1.1 200 OK` in the first line.
