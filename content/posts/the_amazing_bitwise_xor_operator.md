+++
date = "2014-01-12T19:35:25+00:00"
title = "The amazing bitwise XOR operator"
type = "post"
ogtype = "article"
topics = [ "general" ]
+++

One of my colleagues recently mentioned this interview question to me.

>Imagine there is an array which contains 2n+1 elements, n of which have exactly one duplicate. Can you find the one unique element in this array?

This seemed simple enough and I quickly came up with the Ruby solution below.

```ruby
> array = [3, 5, 4, 5, 3]
# => [3, 5, 4, 5, 3]
> count = array.each_with_object(Hash.new(0)) { |number, hash| hash[number] += 1 }
# => {3=>2, 5=>2, 4=>1}
> count.key(1)
# => 4
```

I thought that would be the end of it, but instead I was asked if I could see a way to solve the problem in a significantly more performant way using the XOR operator.

### XOR characteristics

In order to solve this problem with the XOR operator, we first need to understand some of its characteristics. This operator obeys the following rules:

- commutativity: `A^B=B^A`
- associativity: `(A^B)^C=A^(B^C)`
- the identity element is 0: `A^0=A`
- each element is its own inverse: `A^A=0`

Now imagine an array with the elements `[3, 5, 4, 5, 3]`. Using the above rules, we can show that XORing all these elements will leave us with the array's unique element.

```ruby
accum = 3 ^ 5 ^ 4 ^ 5 ^ 3
accum = 0 ^ 3 ^ 5 ^ 4 ^ 5 ^ 3    # 0 is the identity element
accum = 0 ^ 3 ^ 3 ^ 4 ^ 5 ^ 5    # commutativity and associativity rules
accum = 0 ^ 0 ^ 4 ^ 0            # A^A = 0
accum = 4                        # 0 is the identity element
```

Putting this approach in code would give us something like this.

```ruby
> array = [3, 5, 4, 5, 3]
# => [3, 5, 4, 5, 3]
> accum = 0
# => 0
> array.each { |number| accum = accum ^ number }
# => [3, 5, 4, 5, 3]
> accum
# => 4
```

### Benchmarks

Let's use Ruby's `Benchmark` module to do a comparison of both approaches.

```ruby
require 'benchmark'

array = [-1]
1000000.times do |t|
  array << t
  array << t
end

Benchmark.measure do
  count = array.each_with_object(Hash.new(0)) { |number, hash| hash[number] += 1 }
  count.key(1)
end
# => #<Benchmark::Tms:0x007f83fa0279e0 @label="", @real=0.83534, @cstime=0.0, @cutime=0.0, @stime=0.010000000000000009, @utime=0.8300000000000005, @total=0.8400000000000005>

Benchmark.measure do
  accum = 0
  array.each { |number| accum = accum ^ number }
  accum
end
# => #<Benchmark::Tms:0x007f83fa240ba0 @label="", @real=0.136726, @cstime=0.0, @cutime=0.0, @stime=0.0, @utime=0.13999999999999968, @total=0.13999999999999968>
```

So there you have it. Given an array that contains two million elements, the XOR operator approach turns out to be more than 6 times faster than utilizing a hashmap. That's quite a big performance improvement!
