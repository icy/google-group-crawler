##Table of Contents

* [Description](#description)
* [Modification](#modification)
* [Usage](#usage)

##Description

icy/google-group-crawler is a script that downloads all the messages 
from a given google group.

But there may be scenario where someone is intrested in downloading only the 
messages from most discussed topics in the group.

In such cases this  google-group-crawler may not give exact results, so
some modifications were needed to do this.

##Modification

Without disturbing the actual functionality, a piece of new code is added to the existing one.

The block of code added is in the form of a function named _sort_msgs_folder()

The approach followed to download messages from most discussed topics among the group is:

1.Find the files in the msgs folder which have more number of urls that belongs to single topic.

2.Sort those files based on number of lines in each file.(obiviously the topic with more discussions have more urls to actual message).

3.Specify the limit that indicates how many topic to be downloaded.

4.Remove all remaining files from msgs folder.

5.And further processing continous in the same way as it was before.

6.once it was done open a file in mbox and see whether it containd urls to those topics that are mostly discussed.

##Usage

export _GROUP="GroupName"

Change the value based on your requirement to limit how many topics to be downloaded

export _limit="limit value"

The above statement gets effected in the line

wc -l *.* | sort -r | head -n"$_limit"

Now execute the following commands:

./crawler.sh -sh 

./crawler.sh -sh > wget.sh

bash wget.sh

After it is done open mbox folder and see the files created over there.
open those files see whether the intended messages are downloaded or not.

