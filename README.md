## Greyhound

Monitors free space on the partition containing /home/$USER directory. Automatically prompt user with a list of suggested files from the directory /home/$USER to delete. Files to delete are suggested based on their size. Available space calculations use `df` and take into account reserved partition space.

#### Ideas
 - support for -r --refresh [NUM] time argument
 - support for -i --ignore argument that doesn't prompt for file deletion
