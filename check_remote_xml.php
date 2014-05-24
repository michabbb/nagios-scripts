<?

define('STATE_OK',0);
define('STATE_WARNING',1);
define('STATE_CRITICAL',2);
define('STATE_UNKNOWN',3);
define('STATE_DEPENDENT',4);

$username = "xxxxxx";
$password = "xxxxxx";
$remote_url = 'xxxxxxxxxx';

$warning = $argv[1];
$critical = $argv[2];

// Create a stream
$opts = array(
    'http'=>array(
        'method'=>"GET",
        'header' => "Authorization: Basic " . base64_encode("$username:$password")
    )
);

$context = stream_context_create($opts);

// Open the file using the HTTP headers set above
$xml = file_get_contents($remote_url, false, $context);
$xmlstatus = simplexml_load_string($xml);

/** @noinspection PhpUndefinedFieldInspection */
$temp = $xmlstatus->xxxxx;

echo "Temperatur: ".$temp."\n";

if ($temp < $warning) {
    exit(STATE_OK);
} elseif (($temp >= $warning) && ($temp<$critical)) {
    exit(STATE_WARNING);
} elseif ($temp>=$critical) {
    exit(STATE_CRITICAL);
} else {
    exit(STATE_UNKNOWN);
}
