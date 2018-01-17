#!/bin/bash

DATE=$(date)

# Import Reading Notes
cd projects/notes
git add .
git commit -m "Automatic Commit $DATE"
git push
git pull
cd ../../

# Build site
stack build
cd _site
mv .git ../git-save/.git
mv .gitignore ../git-save/.gitignore
cd ..
stack exec site rebuild
cp git-save/.git _site/.git
cp git-save/.gitignore _site/.gitignore
cd _site
git add .
git commit -m "$DATE"
git push -u origin master
cd ..
git add .
git commit -m "$DATE"
git push -u origin hakyll
