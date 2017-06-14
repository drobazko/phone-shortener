DESC
* there are 2 methods (find_variants - slow/silly 1.3s baseed on Postgres, find_variants2 - fast 0.3s based on redis )
# Install Redis & fill it in by 'DictLoader.new.load_to_redis'

TODO
* all classes in one file - should be splitted be file per class/module
* DictIndexator - not necessary to have (legacy class that builds dictionary tree indexed-dictionary.txt)
* NUMBER_SPLITTER - could be represented more concise (e.g. using Array#slice)
* accumulative 'holder' variable should be replced in favor accamulation inside methods
* repeatable @conn & @redis should be declared in single place

CONCERN
Weird but my implementation gives much more combinations:
[["MOT", "OPT", "PUCK"], ["MOT", "OPT", "RUCK"], ["MOT", "OPT", "SUCK"], ["MOT", "ORT", "PUCK"], ["MOT", "ORT", "RUCK"], ["MOT", "ORT", "SUCK"], ["NOT", "OPT", "PUCK"], ["NOT", "OPT", "RUCK"], ["NOT", "OPT", "SUCK"], ["NOT", "ORT", "PUCK"], ["NOT", "ORT", "RUCK"], ["NOT", "ORT", "SUCK"], ["OOT", "OPT", "PUCK"], ["OOT", "OPT", "RUCK"], ["OOT", "OPT", "SUCK"], ["OOT", "ORT", "PUCK"], ["OOT", "ORT", "RUCK"], ["OOT", "ORT", "SUCK"], ["NOUN", "PUP", "TAJ"], ["NOUN", "PUR", "TAJ"], ["NOUN", "PUS", "TAJ"], ["NOUN", "SUP", "TAJ"], ["NOUN", "SUQ", "TAJ"], ["ONTO", "PUP", "TAJ"], ["ONTO", "PUR", "TAJ"], ["ONTO", "PUS", "TAJ"], ["ONTO", "SUP", "TAJ"], ["ONTO", "SUQ", "TAJ"], ["MOT", "OPTS", "TAJ"], ["MOT", "OPUS", "TAJ"], ["MOT", "ORTS", "TAJ"], ["NOT", "OPTS", "TAJ"], ["NOT", "OPUS", "TAJ"], ["NOT", "ORTS", "TAJ"], ["OOT", "OPTS", "TAJ"], ["OOT", "OPUS", "TAJ"], ["OOT", "ORTS", "TAJ"], ["NOUN", "STRUCK"], ["ONTO", "STRUCK"], ["MOTOR", "TRUCK"], ["MOTOR", "USUAL"], ["NOUNS", "TRUCK"], ["NOUNS", "USUAL"], ["MOTORTRUCK"]]

insted from the task description
[[motor,
usual], [noun, struck],
[nouns, truck], [nouns,
usual], [onto, struck],
motortruck]
