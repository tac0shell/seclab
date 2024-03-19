#! /bin/bash

echo "[+] Extracting Vault Secrets"
printf "[?] Login to Vault? [y/N]"
read vault_login
if [[ $vault_login == "y" ]]; then
	vault login
fi
seclab_user=$(vault kv get -field=hades_user hades/hades)
seclab_pw=$(vault kv get -field=hades_password hades/hades)
seclab_ssh_key=$(vault kv get -field=hades_ssh_key hades/hades)
encrypted_pw=$(openssl passwd -6 $seclab_pw)
echo "[+] Moving example files to active files"
for f in $(find ./ -name "user-data.example" -or -name "*.preseed.example"); do
	cp $f "${f%.example}"
done
echo $encrypted_pw
echo "[+] Adding encrypted secret to user-data/preseed files"
for f in $(find ./ -name "user-data" -or -name "*.preseed"); do
	cp $f $f.bak
	sed -i "s/SECLAB_USER/$seclab_user/g" $f
	sed -i "s:SECLAB_PASSWORD:${encrypted_pw}:g" $f
	sed -i "s:SECLAB_SSH_KEY:$seclab_ssh_key:g" $f
done
exit 0
