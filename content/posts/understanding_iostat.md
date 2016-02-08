+++
date = "2015-08-24T19:47:55+00:00"
title = "Understanding iostat"
type = "post"
ogtype = "article"
topics = [ "linux" ]
+++

I've been spending a lot of time lately looking at I/O performance and reading up about the `iostat` command. While this command provides a wealth of I/O performance data, the sheer amount of it all can make it hard to see the forest for the trees. In this post, we'll talk about interpreting this data. Before we continue, I would first like to thank the authors of the blog posts mentioned below, as each of these has helped me understand `iostat` and its many complexities just a little bit better.

* [Measuring disk usage in linux (%iowait vs IOPS)](http://www.thattommyhall.com/2011/02/18/iops-linux-iostat/)
* [Basic I/O monitoring on linux](http://www.pythian.com/blog/basic-io-monitoring-on-linux/)
* [Two traps in iostat: %util and svctm](http://brooker.co.za/blog/2014/07/04/iostat-pct.html)
* [What exactly is "iowait"?](https://blog.pregos.info/wp-content/uploads/2010/09/iowait.txt)
* [Measuring & optimizing I/O performance](https://www.igvita.com/2009/06/23/measuring-optimizing-io-performance/)
* [Iostat](http://dom.as/2009/03/11/iostat/)
* [Beware of svctm in linux's iostat](http://www.xaprb.com/blog/2010/09/06/beware-of-svctm-in-linuxs-iostat/)
* [Analyzing I/O performance](http://www.psce.com/blog/2012/04/18/analyzing-io-performance/)

The `iostat` command can display both basic and extended metrics. We'll take a look at the basic metrics first before moving on to extended metrics in the remainder of this post. Note that this post will not go into detail about every last metric. Instead, I have decided to focus on just those metrics that I found to be especially useful, as well as those that seem to be often misunderstood.

### Basic iostat metrics

The `iostat` command lists basic metrics by default. The `-m` parameter causes metrics to be displayed in megabytes per second instead of blocks or kilobytes per second. Using the `5` parameter causes `iostat` to recalculate metrics every 5 seconds, thereby making the numbers an average over this interval.

```bash
$ iostat -m 5

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           8.84    0.16    3.91    7.73    0.04   79.33

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
xvdap1           46.34         0.33         1.03    2697023    8471177
xvdb              0.39         0.00         0.01       9496      71349
xvdg             65.98         1.34         0.97   11088426    8010609
xvdf            205.17         1.62         2.68   13341297   22076001
xvdh             51.16         0.64         1.43    5301463   11806257
```

The `tps` number here is the number of I/O Operations Per Second (IOPS). Wikipedia has [a nice list of average IOPS for different storage devices](https://en.wikipedia.org/wiki/IOPS#Examples). This should give you a pretty good idea of the I/O load on your machine.

Some people put a lot of faith in the `%iowait` metric as an indicator of I/O performance. However, `%iowait` is first and foremost a CPU metric that measures the percentage of time the CPU is idle while waiting for an I/O operation to complete. This metric is heavily influenced by both your CPU speed and CPU load and is therefore easily misinterpreted.

For example, consider a system with just two processes: the first one heavily I/O intensive, the second one heavily CPU intensive. As the second process will prevent the CPU from going idle, the `%iowait` metric will stay low despite the first process's high I/O utilization. Other examples illustrating the deceptive nature of `%iowait` can be found [here](https://blog.pregos.info/wp-content/uploads/2010/09/iowait.txt) ([mirror](https://gist.github.com/vaneyckt/58028fb0ddbdbf561e60)). The only thing `%iowait` really tells us is that the CPU occasionally idles while there is an outstanding I/O request, and could thus be made to handle more computational work.

### Extended iostat metrics

Let's now take a look at the extended metrics by calling the `iostat -x` command.

```bash
$ iostat -mx 5

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           8.84    0.16    3.91    7.73    0.04   79.33

Device:         rrqm/s   wrqm/s     r/s     w/s    rMB/s    wMB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
xvdap1            0.57     6.38   20.85   25.49     0.33     1.03    59.86     0.27   17.06   13.15   20.25   1.15   5.33
xvdb              0.00     1.93    0.10    0.29     0.00     0.01    51.06     0.00    7.17    0.33    9.66   0.09   0.00
xvdg              0.55     4.69   42.04   23.94     1.34     0.97    71.89     0.44    6.63    6.82    6.28   1.16   7.67
xvdf              7.33    41.35  132.66   72.52     1.62     2.68    42.87     0.49    2.37    2.79    1.59   0.36   7.42
xvdh              0.00     4.54   15.54   35.63     0.64     1.43    83.04     0.00   10.22    8.39   11.02   1.30   6.68
```

The `r/s` and `w/s` numbers show the amount of read and write requests issued to the I/O device per second. These numbers provide a more detailed breakdown of the `tps` metric we saw earlier, as `tps = r/s + w/s`.

The `avgqu-sz` metric is an important value. Its name is rather poorly chosen as it doesn't actually show the number of operations that are queued but not yet serviced. Instead, it shows [the number of operations that were either queued, or being serviced](http://www.xaprb.com/blog/2010/01/09/how-linux-iostat-computes-its-results). Ideally, you'd want to have an idea of this value during normal operations for use as a baseline number for when trouble occurs. Single digit numbers with the occasional double digit spike are safe(ish) values. Triple digit numbers generally are not.

The `await` metric is the average time from when a request was put in the queue to when the request was completed. This is the sum of the time a request was waiting in the queue and the time our storage device was working on servicing the request. This metric is highly dependent on the number of items in the queue. Much like `avgqu-sz`, you'll want to have an idea of the value of this metric during normal operations for use as a baseline.

Our next metric is `svctm`. You'll find a lot of older blog posts that go into quite some detail about this one. However, `man iostat` makes it quite clear that this metric has since been deprecated and should no longer be trusted. We will therefore ignore it.

Our last metric is `%util`. Just like `svctm`, this metric has been touched by the progress of technology as well. The `man iostat` pages contain the information shown below.

> **%util**
>
> Percentage of elapsed time during which I/O requests were issued to the device (bandwidth utilization for the device). Device saturation occurs when this value is close to 100% for devices serving requests serially. But for devices serving requests in parallel, such as RAID arrays and modern SSDs, this number does not reflect their performance limits.

It’s common to assume that the closer a device gets to 100% utilization, the more saturated it becomes. This is true when the storage device corresponds to a single magnetic disk as such a device can only serve one request at a time. However, a single SSD or a RAID array consisting of multiple disks can serve multiple requests simultaneously. For such devices, `%util` essentially indicates the percentage of time that the device was busy serving one or more requests. Unfortunately, this value tells us absolutely nothing about the maximum number of simultaneous requests such a device can handle. This metric should therefore not be treated as a saturation indicator for either SSDs or RAID arrays.

### Conclusion

By now it should be clear that `iostat` is an incredibly powerful tool, the metrics of which can take some experience to interpret correctly. In a perfect world your machines should regularly be writing these metrics to a monitoring service, so you'll always have access to good baseline numbers. In an imperfect world, just knowing your baseline IOPS values will already go a long way when trying to diagnose whether a slowdown is I/O related.
