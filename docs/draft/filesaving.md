# Notes on File Saving

## Ask user to save another file when fail to save

It is very possible that a user cannot save the current editing file. The user may open a readonly file, or try to save a new buffer to a folder that the uer cannot write to. Currently the editor only prompt an error, but it could be better if the editor also asks the user to write the file to another path to prevent the data lose.

## Automatic backup

zago takes lots of features from nano. Nano has a design to create backups for the users. 
