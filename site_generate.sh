#!/bin/bash

DATE=$(date)

stack build
cd _site
mv .git ../git-save/.git
mv .gitignore ../git-save/.gitignore
cd ..
stack exec site rebuild
cp git-save/.git _site/.git
cp git-save/.gitignore _site/.gitignore
cd _site
git add -A
git commit -m "$DATE"
git push -u origin master
cd ..
git add -A
git commit -m "$DATE"
git push -u origin hakyll
