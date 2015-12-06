#!/bin/sh

hugo --theme=hyde
git push origin :master
git subtree push --prefix public/ origin master
