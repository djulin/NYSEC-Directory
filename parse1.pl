#use feature 'signatures';

#$debug = 0xffff;
$debug = 0;
$DEBUG_INPUT = 0x1;
$DEBUG_PARSING = 0x2;
$DEBUG_OUTPUT = 0x4;

$input = "";
$atEOR = 0;
$countMatches = 0;

sub trim($input) {
    $input = shift(@_);
    $input =~ s/^\s+|\s+$//g;
    return $input;
}

sub getNextInput($input) {
    $input = shift(@_);
    return "" if $atEOR;
    $input = &trim($input);
    if (length($input)) {
	return $input;
    } else {
	$input = <>;
	$input = &trim($input);
	if (length($input)) {
	    print "    INPUT \"$input\"\n" if ($debug & $DEBUG_INPUT);
	    return $input;
	} else {
	    $atEOR = 1;
	    print "    EOR\n" if ($debug & $DEBUG_INPUT);
	    return "";
	}
    }
}

sub getNextRecord() {
    $atEOR = 0;
    while (<>) {
	$input = &trim($_);
	if (length($input)) {
	    print "RECORD \"$input\"\n" if ($debug & $DEBUG_INPUT);
	    return($input);
	}
    }
    print "EOF\n" if ($debug & $DEBUG_INPUT);
    exit;
}

sub parseFullName($input) {
    $input = shift(@_);
    if ($input =~ /^([a-zA-Z.()&\s]+)(.*)$/) {
        $token = $1;
	print "        fullName=\"$token\"\n" if ($debug & $DEBUG_PARSING);
	$countMatches++;
        $input = &getNextInput($2);
        return $token;
    }
    return "";
}

$REGEX_ADDRESS1 = qr/(.*?\d.*?)/;
$REGEX_ADDRESS2 = qr/((New York|[A-Z][A-Za-z]+),\s+[A-Z]{2}\s+[0-9]{5})/;

sub parseAddress1($input) {
    $input = shift(@_);
#    if ($input =~ /^(.*?\d.*?)$/) {
#    if ($input =~ /^${$REGEX_ADDRESS1}$/) {
    if ($input =~ /^${$REGEX_ADDRESS1}${REGEX_ADDRESS2}?$/) {
        $token = $1;
	print "        address1=\"$token\"\n" if ($debug & $DEBUG_PARSING);
	$countMatches++;
        $input = &getNextInput($2);
        return $token;
    }
    return "";
}

sub parseAddress2($input) {
    $input = shift(@_);
    if ($input =~ /^${REGEX_ADDRESS2}$/) {
        $token = $1;
	print "        address2=\"$token\"\n" if ($debug & $DEBUG_PARSING);
	$countMatches++;
        $input = &getNextInput("");
        return $token;
    }
    return "";
}

sub parsePhone($input) {
    $input = shift(@_);
    if ($input =~ /^(.*?\b\d{3}\s*-\s*\d{3}-\d{4}\b.*)$/) {
        $token = $1;
	print "        phone=\"$token\"\n" if ($debug & $DEBUG_PARSING);
	$countMatches++;
        $input = &getNextInput("");
        return $token;
    }
    return "";
}

sub parseEmail($input) {
    $input = shift(@_);
    if ($input =~ /^(.*?\b\S+@\S+\b.*)$/) {
        $token = $1;
	print "        email=\"$token\"\n" if ($debug & $DEBUG_PARSING);
	$countMatches++;
        $input = &getNextInput("");
        return $token;
    }
    return "";
}

print "fullName,address1,address2,phone1,phone2,phone3,email1,email2,email3,rest\n";

while (1) {
    $input = &getNextRecord();
    $countMatches = 0;
    $fullName = &parseFullName($input);
    $address1 = &parseAddress1($input);
    $address2 = &parseAddress2($input);
    $phone1 = &parsePhone($input);
    $phone2 = &parsePhone($input);
    $phone3 = &parsePhone($input);
    $email1 = &parseEmail($input);
    $email2 = &parseEmail($input);
    $email3 = &parseEmail($input);
    $rest = "";
    while (! $atEOR) {
	$input = &getNextInput("");
	if (length($input)) {
	    $rest = $rest . " " . $input;
	}
    }
    if (length($fullName) && ($countMatches >= 3)) {
	print "    VALID RECORD\n" if ($debug & $DEBUG_OUTPUT);
	print "\"$fullName\",\"$address1\",\"$address2\",\"$phone1\",\"$phone2\",\"$phone3\",\"$email1\",\"$email2\",\"$email3\",\"$rest\"\n";
    } else {
	print "    SKIPPING MALFORMED RECORD\n" if ($debug & $DEBUG_OUTPUT);
	print "\"MALFORMED RECORD $fullName\",\"$address1\",\"$address2\",\"$phone1\",\"$phone2\",\"$phone3\",\"$email1\",\"$email2\",\"$email3\",\"$rest\"\n";
    }
}

=comment
/* TODO
- use "my" for local vars
- swallowing some unrecognized input, not in $rest
- specific columns for home phone, work phone, etc.
- phone number on same line as address
- specific attribute for apartment number
- apartment number on same line as city
- multiple emails on the same line
*/
=cut

