# Pipe `ip r` or `ip -6 r` into this script
# The script returns one route per line.
# Each line consists of three parts (;-delimited):
# - The first part is the route target
# - The second part is the `via` part of the route
# - The third part is the `dev` part of the route
# Both via and dev may be empty.

{
	if ($1 == "unreachable" || $1 ~ /^fe80::/)
		next

	# Parse fields
	isVia = 0
	isDev = 0
	via = ""
	dev = ""
	for (i=1;i<=NF;i++) {
		if (isVia == 1)
			via = $i
		if (isDev == 1)
			dev = $i
		# State
		if ($i == "via")
			isVia = 1
		else
			isVia = 0
		if ($i == "dev")
			isDev = 1
		else
			isDev = 0
	}

	# No loopback routes
	if (dev == "lo")
		next

	print $1";"via";"dev
}
