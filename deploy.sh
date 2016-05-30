#!/bin/sh

hugo --theme=hyde
cp -f favicon.ico ./public/favicon.ico
git push origin :master
git subtree push --prefix public/ origin master
