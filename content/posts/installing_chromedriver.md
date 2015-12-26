+++
date = "2015-08-16T19:43:34+00:00"
title = "Installing Chromedriver"
type = "post"
ogtype = "article"
topics = [ "linux" ]
+++

Some time ago I needed to install [chromedriver](https://sites.google.com/a/chromium.org/chromedriver/) on a ubuntu machine. While this wasn't too hard, I was nevertheless surprised by the number of open [StackOverflow](https://stackoverflow.com/) questions on this topic. So I decided to leave some notes for my future self.

First of all, let's install chromedriver.

```bash
LATEST_RELEASE=$(curl http://chromedriver.storage.googleapis.com/LATEST_RELEASE)
wget http://chromedriver.storage.googleapis.com/$LATEST_RELEASE/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
rm chromedriver_linux64.zip
sudo mv chromedriver /usr/local/bin
```

Let's see what happens when we try and run it.

```nohighlight
$ chromedriver
    chromedriver: error while loading shared libraries: libgconf-2.so.4:
    cannot open shared object file: No such file or directory
```

That's a bit unexpected. Luckily we can easily fix this.

```bash
$ sudo apt-get install libgconf-2-4
```

Now that we have a functioning chromedriver, the only thing left to do is to install Chrome. After all, chromedriver can't function without Chrome.

```bash
$ wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
$ sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
$ sudo apt-get update
$ sudo apt-get install google-chrome-stable
```

And that's it. You should be good to go now.
