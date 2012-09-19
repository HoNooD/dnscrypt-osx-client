#! /bin/sh

RESOLVER_DIR='/etc/resolver'

. ./common.inc

[ -r "$DOMAINS_EXCEPTIONS_FILE" ] &&
  DOMAINS_EXCEPTIONS="$(cat "$DOMAINS_EXCEPTIONS_FILE") $DOMAINS_EXCEPTIONS"

get_gw() {
  route -n get default | while read line; do
    case "$line" in
      gateway:\ *)
        echo "$line" | sed 's/ *gateway: *//'
        return
      ;;
    esac
  done
}

get_dhcp_dns() {
  cat "${STATES_DIR}/dhcp-dns" 2> /dev/null
}

name_servers=$(get_dhcp_dns || get_gw)

[ x"$name_servers" = 'x' ] && exit 0

default_domain=$(./get-current-default-domain.sh)

mkdir -p "$RESOLVER_DIR" || exit 1
name_server="$gw"
for domain in $DOMAINS_EXCEPTIONS; do
  if [ x"$default_domain" != 'x' ]; then
    echo "$domain" | grep -c ".*${default_domain}" > /dev/null
    [ $? = 0 ] && continue
  fi
  echo '# automatically generated by the dnscrypt user interface' \
    > "${RESOLVER_DIR}/${domain}"
  for name_server in $name_servers; do
    echo "nameserver ${name_server}" >> "${RESOLVER_DIR}/${domain}"
  done
done
exit 0