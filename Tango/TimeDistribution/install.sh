#!/bin/sh
echo "#!/usr/bin/env python3" > TimeDistributionMaster
cat TimeDistributionMaster.py >> TimeDistributionMaster
chmod +x TimeDistributionMaster
sudo cp TimeDistributionMaster /usr/local/tango_servers/

echo "#!/usr/bin/env python3" > TimeDistributionChannel
cat TimeDistributionChannel.py >> TimeDistributionChannel
chmod +x TimeDistributionChannel
sudo cp TimeDistributionChannel /usr/local/tango_servers/
