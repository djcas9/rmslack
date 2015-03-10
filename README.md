# rmslack

[![Build Status](http://104.236.125.70/api/badge/github.com/mephux/rmslack/status.svg?branch=master)](http://104.236.125.70/github.com/mephux/rmslack)

Remove all messages from a given slack channel. Stupid little app but helpful.

# Why

slack does not support the option to delete all messages from a channel. You could email
them and ask but who has time for that crap.

# Usage

`rmslack --token <TOKEN-HERE>`

* note: you can find you token here. https://api.slack.com/web at the bottom.

Here is some example output.

```
INFO[0000] Initializing rmslack Version: 0.1.0.
INFO[0000] Fetching channel list.

[0] blahblah (C0352348H)
[1] word (C035456465FF)
[2] foo (C03451J5)
[3] bar (C03234U4)
[4] random (C035428K)

Which channel would you like to purge messages from?
4
INFO[0013] Fetching history for channel: random
INFO[0014] Removing Next Message Batch. Size: 100
INFO[0017] Removing Next Message Batch. Size: 81
INFO[0019] All Done!
```

