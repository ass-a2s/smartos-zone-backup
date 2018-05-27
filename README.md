
create the SSH Key on SmartOS:
=============================
```
   ssh-keygen -t ed25519 -o -a 100
```

* Example:
```
   [root@edv-test-smartos /zones]# ssh-keygen -t ed25519 -o -a 100
   Generating public/private ed25519 key pair.
   Enter file in which to save the key (/root/.ssh/id_ed25519): /zones/id_edv-test-smartos
```

Usage:
======
```
   [root@edv-test-smartos /zones/ass.de/admin]# ./smartos-zone-backup.sh
   WARNING: smartos-zone-backup is experimental and its not ready for production. Do it at your own risk.

   usage: ./smartos-zone-backup.sh { backup | send | clean | systemconfigsbackup }
   [root@edv-test-smartos /zones/ass.de/admin]#
```

Example: backup
===============
```
   [root@edv-test-smartos /zones/ass.de/admin]# ./smartos-zone-backup.sh backup
   [   OK   ] using smartos-zone-backup config
   [   OK   ] find stopped vms for backup purposes
   [   OK   ] 'zones config backup'
   [   OK   ] 'sync buffer'

   list created snapshots:
   zones/9456cc7a-e8e2-6761-ad24-c864b10c8e91@_SNAP_041116-17                0      -  1,19G  -
   zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8@_SNAP_041116-17                0      -  7,47G  -
   zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8-disk0@_SNAP_041116-17          0      -  16,7G  -


   smartos-zone-backup finished.
   [root@edv-test-smartos /zones/ass.de/admin]#
```

Example: send
=============
```
   [root@edv-test-smartos /zones/ass.de/admin]# ./smartos-zone-backup.sh send
   [   OK   ] using smartos-zone-backup config
   [   OK   ] 'sync buffer'

   list created snapshots:
   zones/9456cc7a-e8e2-6761-ad24-c864b10c8e91@_SNAP_041116-17                0      -  1,19G  -
   zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8@_SNAP_041116-17                0      -  7,47G  -
   zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8-disk0@_SNAP_041116-17          0      -  16,7G  -

   receiving full stream of zones/9456cc7a-e8e2-6761-ad24-c864b10c8e91@_SNAP_041116-17 into offsite/edv-test-smartos/zones/9456cc7a-e8e2-6761-ad24-c864b10c8e91@_SNAP_041116-17
   received 2.05GB stream in 36 seconds (58.4MB/sec)
   receiving full stream of zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8@_SNAP_041116-17 into offsite/edv-test-smartos/zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8@_SNAP_041116-17
   received 8.06GB stream in 133 seconds (62.1MB/sec)
   receiving full stream of zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8-disk0@_SNAP_041116-17 into offsite/edv-test-smartos/zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8-disk0@_SNAP_041116-17
   received 22.7GB stream in 429 seconds (54.3MB/sec)
   [   OK   ] 'last state: zfs send'

   smartos-zone-backup finished.
   [root@edv-test-smartos /zones/ass.de/admin]#
```

Example: clean
==============
```
   [root@edv-test-smartos /zones/ass.de/admin]# ./smartos-zone-backup.sh clean
   [   OK   ] using smartos-zone-backup config
   [   OK   ] 'sync buffer'
   will destroy zones/9456cc7a-e8e2-6761-ad24-c864b10c8e91@_SNAP_041116-17
   will reclaim 4,28M
   will destroy zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8@_SNAP_041116-17
   will reclaim 41,1K
   will destroy zones/ab2a6060-8a3b-e4a2-f930-8e3d885da3b8-disk0@_SNAP_041116-17
   will reclaim 765M
   [   OK   ] 'remove all _SNAP_ snapshots'

   smartos-zone-backup finished.
   [root@edv-test-smartos /zones/ass.de/admin]#
```

Example: systemconfigsbackup
============================
```
   [root@assg15-labor /zones/ass.de/admin]# ./smartos-zone-backup.sh systemconfigsbackup
   [   OK   ] using smartos-zone-backup config
   [   OK   ] 'sync buffer'
   [   OK   ] 'create snapshot: zones/usbkey'
   [   OK   ] 'create snapshot: zones/opt'
   [   OK   ] 'create snapshot: zones/ass.de'
   receiving full stream of zones/usbkey@_SNAP_180512-11 into offsite/assg15/zones/usbkey@_SNAP_180512-11
   received 73.2KB stream in 1 seconds (73.2KB/sec)
   [   OK   ] 'transfer snapshot: zones/usbkey'
   receiving full stream of zones/opt@_SNAP_180512-11 into offsite/assg15/zones/opt@_SNAP_180512-11
   received 36.1MB stream in 1 seconds (36.1MB/sec)
   [   OK   ] 'transfer snapshot: zones/opt'
   receiving full stream of zones/ass.de@_SNAP_180512-11 into offsite/assg15/zones/ass.de@_SNAP_180512-11
   received 16.8GB stream in 278 seconds (61.7MB/sec)
   [   OK   ] 'transfer snapshot: zones/ass.de'

   smartos-zone-backup finished.
   [root@assg15-labor /zones/ass.de/admin]#
```

Errata
======
* 07.11.2016 - xargs exceed the maximum length
* http://offbytwo.com/2011/06/26/things-you-didnt-know-about-xargs.html

