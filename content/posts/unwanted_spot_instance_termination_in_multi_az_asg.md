+++
date = "2015-01-24T19:17:53+00:00"
title = "Unwanted spot instance termination in multi-AZ ASG"
type = "post"
ogtype = "article"
topics = [ "aws" ]
+++

An auto scaling group is an AWS abstraction that facilitates increasing or decreasing the number of EC2 instances within your application's architecture. Spot instances are unused AWS servers that are auctioned off for little money. The combination of these two allows for large auto scaling groups at low costs. However, you can lose your spot instances at a moment's notice as soon as someone out there wants to pay more than you do.

Knowing all this, I recently found myself looking into why AWS was terminating several of our spot instances every day. We were bidding 20% over the average price, so it seemed unlikely that this was being caused by a monetary issue. Nevertheless, we kept noticing multiple spot instances disappearing on a daily basis.

It took a while to get to the bottom of things, but it turned out that this particular problem was being caused by an unfortunate combination of:

* our auto scaling group spanning multiple availability zones
* our scaling code making calls to `TerminateInstanceInAutoScalingGroup`

The step-by-step explanation of this issue was as follows:

* our scaling code was asking AWS to put 10 instances in our auto scaling group
* AWS obliged and put 5 instances in availability zone A and another 5 in zone B
* some time later our scaling code would decide that 2 specific instances were no longer needed. A call would be made to `TerminateInstanceInAutoScalingGroup` to have just these 2 specific instances terminated.
* if these 2 instances happened to be in the same availability zone, then one zone would now have 3 instances, while the other one would have 5
* AWS would detect that both zones were no longer balanced and would initiate a rebalancing action. This rebalancing action would terminate one of the instances in the zone with 5 instances, and spin up another instance in the zone with 3 instances.

So while this action did indeed end up rebalancing the instances across the different availability zones, it also inadvertently ended up terminating a running instance.

The relevant entry from the [AWS Auto Scaling docs](http://awsdocs.s3.amazonaws.com/AutoScaling/latest/as-dg.pdf) is shown below.

>**Instance Distribution and Balance across Multiple Zones**

>Auto Scaling attempts to distribute instances evenly between the Availability Zones that are enabled for your Auto Scaling group. Auto Scaling attempts to launch new instances in the Availability Zone with the fewest instances. If the attempt fails, however, Auto Scaling will attempt to launch in other zones until it succeeds.

>Certain operations and conditions can cause your Auto Scaling group to become unbalanced. Auto Scaling compensates by creating a rebalancing activity under any of the following conditions:

>* You issue a request to change the Availability Zones for your group.
>* You call `TerminateInstanceInAutoScalingGroup`, which causes the group to become unbalanced.
>* An Availability Zone that previously had insufficient capacity recovers and has additional capacity available.

>Auto Scaling always launches new instances before attempting to terminate old ones, so a rebalancing activity will not compromise the performance or availability of your application.

>**Multi-Zone Instance Counts when Approaching Capacity**

>Because Auto Scaling always attempts to launch new instances before terminating old ones, being at or near the specified maximum capacity could impede or completely halt rebalancing activities. To avoid this problem, the system can temporarily exceed the specified maximum capacity of a group by a 10 percent margin during a rebalancing activity (or by a 1-instance margin, whichever is greater). The margin is extended only if the group is at or near maximum capacity and needs rebalancing, either as a result of user-requested rezoning or to compensate for zone availability issues. The extension lasts only as long as needed to rebalance the group—typically a few minutes.

I'm not sure about the best way to deal with this behavior. In our case, we just restricted our auto scaling group to one availability zone. This was good enough for us as none of the work done by our spot instances is critical. Going through the [docs](http://awsdocs.s3.amazonaws.com/AutoScaling/latest/as-dg.pdf), it seems one approach might be to disable the `AZRebalance` process. However, I have not had the chance to try this, so I cannot guarantee a lack of unexpected side effects.
