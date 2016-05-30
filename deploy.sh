#!/bin/sh

cp -f favicon.ico ./public/favicon.ico
hugo --theme=hyde
git push origin :master
git subtree push --prefix public/ origin master
