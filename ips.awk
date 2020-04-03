# Pipe `ip a` into this script
# The script returns one line per interface.
# Each line begins with the interface name, and all IPs (v4 and v6, CIDR notation), separated by ;.

BEGIN {
	first = 1;
}
{
	if ($1 ~ /[0-9]*:/) {
		if ($2 != "lo:") {
			inter = substr($2, 1, length($2)-1);
			printedInt = 0;
		}
	}
	if ($1 ~ /^inet(6)?/) {
		scope = 0;
		p = 0;
		for (i=1;i<=NF;i++) {
			if (scope == 1) {
				if ($i != "host" && $i != "link")
					p = 1;
			}
			if ($i == "scope")
				scope = 1;
			else
				scope = 0;
		}
		if (p == 1) {
			if (printedInt == 0) {
				if (first == 0)
					printf "\n";
				printf inter;
				printedInt = 1;
				first = 0;
			}
			printf ";"$2;
		}
	}
}
END {
	printf "\n";
}
