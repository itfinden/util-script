
#!/bin/sh
#
# Check if an IP address is listed on one of the 
# following blacklists. The format is chosen to 
# make it easy to add or delete. The shell script
# dig +short unix.stackexchange.com
# sh check_rbl.sh 201.217.242.79 2>&1 | tee output.txt | mail -s "Email subject" cm@itfinden.combined
# will strip multiple white spaces.

BLISTS="
    dnsbl.httpbl.org
    cbl.abuseat.org
    dnsbl.sorbs.net
    bl.spamcop.net
    zen.spamhaus.org
    combined.njabl.org
    bl.score.senderscore.com
    bl.mailspike.net
	bl.spameatingmonkey.net
	b.barracudacentral.org
	bl.deadbeef.com
	bl.emailbasura.org
	bl.spamcop.net
	blackholes.five-ten-sg.com
	blacklist.woody.ch
	bogons.cymru.com
	cbl.abuseat.org
	cdl.anti-spam.org.cn
	combined.abuse.ch
	combined.rbl.msrbl.net
	db.wpbl.info
	dnsbl-1.uceprotect.net
	dnsbl-2.uceprotect.net
	dnsbl-3.uceprotect.net
	dnsbl.inps.de
	dnsbl.sorbs.net
	drone.abuse.ch
	drone.abuse.ch
	duinv.aupads.org
	dul.dnsbl.sorbs.net
	dul.ru
	dyna.spamrats.com
	dynip.rothen.com
	http.dnsbl.sorbs.net
	images.rbl.msrbl.net
	ips.backscatterer.org
	ix.dnsbl.manitu.net
	korea.services.net
	misc.dnsbl.sorbs.net
	noptr.spamrats.com
	ohps.dnsbl.net.au
	omrs.dnsbl.net.au
	orvedb.aupads.org
	osps.dnsbl.net.au
	osrs.dnsbl.net.au
	owfs.dnsbl.net.au
	owps.dnsbl.net.au
	pbl.spamhaus.org
	phishing.rbl.msrbl.net
	probes.dnsbl.net.au
	proxy.bl.gweep.ca
	proxy.block.transip.nl
	psbl.surriel.com
	rbl.interserver.net
	rdts.dnsbl.net.au
	relays.bl.gweep.ca
	relays.bl.kundenserver.de
	relays.nether.net
	residential.block.transip.nl
	ricn.dnsbl.net.au
	rmst.dnsbl.net.au
	sbl.spamhaus.org
	short.rbl.jp
	smtp.dnsbl.sorbs.net
	socks.dnsbl.sorbs.net
	spam.abuse.ch
	spam.dnsbl.sorbs.net
	spam.rbl.msrbl.net
	spam.spamrats.com
	spamrbl.imp.ch
	t3direct.dnsbl.net.au
	tor.dnsbl.sectoor.de
	torserver.tor.dnsbl.sectoor.de
	ubl.lashback.com
	ubl.unsubscore.com
	virbl.bit.nl
	virus.rbl.jp
	virus.rbl.msrbl.net
	web.dnsbl.sorbs.net
	wormrbl.imp.ch
	xbl.spamhaus.org
	zen.spamhaus.org
	zombie.dnsbl.sorbs.net



"
# register at http://www.projecthoneypot.org/httpbl_api.php to
# obtain an API-key
HTTPbl_API_KEY="ybopxmetwuhk"
# simple shell function to show an error message and exit
#  $0  : the name of shell script, $1 is the string passed as argument
#  >&2  : redirect/send the message to stderr
ERROR() {
  echo $0 ERROR: $1 >&2
  exit 2
}

# -- Sanity check on parameters
[ $# -ne 1 ] && ERROR 'Please specify a single IP address'
# -- if the address consists of 4 groups of minimal 1, maximal digits,
#    separated by '.'
# -- reverse the order
# -- if the address does not match these criteria the variable
#    'reverse will be empty'
reverse=$(echo $1 |
sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")
if [ "x${reverse}" = "x" ] ; then
      ERROR  "IMHO '$1' doesn't look like a valid IP address"
      exit 1
else
	  ERROR "estamos todos bien"
fi

# Assuming an IP address of 11.22.33.44 as parameter or argument
# If the IP address in $0 passes our crude regular expression
# check, the variable  ${reverse} will contain 44.33.22.11
# In this case the test will be:
#   [ "x44.33.22.11" = "x" ]
# This test will fail and the program will continue
# An empty '${reverse}' means that shell argument $1 doesn't pass our
# simple IP address check. In that case the test will be:
#   [ "x" = "x" ]
# This evaluates to true, so the script will call the ERROR function
# and quit
# -- do a reverse ( address -> name) DNS lookup
REVERSE_DNS=$(dig +short -x $1)
echo IP $1 NAME ${REVERSE_DNS:----}

# -- cycle through all the blacklists
for BL in ${BLISTS} ; do
    # print the UTC date (without linefeed)
    printf $(env TZ=UTC date "+%Y-%m-%d_%H:%M:%S")
    # show the reversed IP and append the name of the blacklist
    if [ "$BL" == "dnsbl.httpbl.org" ];
    then
      printf "%-50s" " ${HTTPbl_API_KEY}.${reverse}.${BL}."
    else
      printf "%-50s" " ${reverse}.${BL}."
    fi
    # use dig to lookup the name in the blacklist
    # echo "$(dig +short -t a ${reverse}.${BL}. |  tr 'n' ' ')"
    if [ "$BL" == "dnsbl.httpbl.org" ];
    then
      LISTED="$(dig +short -t a ${HTTPbl_API_KEY}.${reverse}.${BL}.)"
      echo ${LISTED:----}
    else
      LISTED="$(dig +short -t a ${reverse}.${BL}.)"
      echo ${LISTED:----}
    fi
done
# --- EOT ------
