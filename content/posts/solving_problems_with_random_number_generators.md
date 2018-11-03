+++
date = "2018-11-04T11:12:56+00:00"
title = "Solving problems with random number generators"
type = "post"
ogtype = "article"
topics = [ "ruby" ]
+++

I recently came across the [following blog post](https://dev.to/rpalo/its-ruby-there-must-be-a-better-way-4f7e) detailing a very nice Ruby solution to the following problem:

- you are constantly creating robots, each of which must be given a unique name
- this name must follow the pattern `letter letter number number number`
- names need to be assigned at random, e.g. you can't just call your first robot `AA000`, your second robot `AA001`, ...
- there needs to be a way to reset this name generator

The author came up with a very beautiful Ruby solution that makes clever use of ranges. In essence, it goes a little something like this:

```ruby
class Generator
  def initialize
    init_rng
  end

  def next
    @names.next
  end

  def reset
    init_rng
  end

  private

  def init_rng
    @names = ('AA000'..'ZZ999').to_a.shuffle.each
  end
end

gen = Generator.new
gen.next # => SX696
gen.next # => VW329
```

There's some really good stuff going on here. I had no idea ranges in Ruby where smart enough to deal with `('AA000'..'ZZ999')`. The idea of storing `@names` as an enumerator is very nice as well. The author should feel proud for coming up with it.


### Can we make it scale?

Reading through the code, it struck me just how diabolical this problem actually was. Because of the requirement for names to be assigned at random, we need to generate all elements in the range `('AA000'..'ZZ999')` during initialization in order for us to be able to `shuffle` them into a random order. Unfortunately, this doesn't really scale well for larger ranges. Some computation times for different ranges are shown below.

```bash
'AA000'..'ZZ999'     - 0.3 sec
'AAA000'..'ZZZ999'   - 9.8 sec
'AAAA000'..'ZZZZ999' - 133 sec
```

I started wondering just how hard it would be to solve this problem for arbitrarily large ranges. As it turns out, it's totally possible, but we need to rephrase our robot naming problem into two completely different subproblems:

1. Can we come up with a method that takes a number as input and transforms it into the relevant element of the range `'AA000'..'ZZ999'` as output? e.g. can we transform the number `0` into the string `AA000`, the number `1` into the string `AA001`, ... ?

2. Can we come up with a random number generator that'll allow us to specify a range and that will then return all elements of this range exactly once in a random order?

If we can solve both of these subproblems, then the original problem can be solved by writing such a random number generator and transforming each random number returned by it into the desired range. The nice thing about this approach is that generating a new name will always take the same amount of time regardless of the size of the range as we now no longer have to compute all elements in the range during initialization.


### Designing a transformation function

The transformation function is by far the easier subproblem of the two. There isn't really much to say about constructing such a function. We'll start by writing a function that can transform an input into a 5 digit binary number. Once this is done, we'll just modify this function to transform the input into the range `'AA000'..'ZZ999'` instead.

Writing a function that can create 5 digit binary numbers is pretty straightforward. It goes a little something like this:

```ruby
def transform(number)
  binary = []

  binary << number % 2
  binary = number / 2

  binary << number % 2
  binary = number / 2

  binary << number % 2
  binary = number / 2

  binary << number % 2
  binary = number / 2

  binary << number % 2
  binary = number / 2

  binary.reverse.join
end

transform(17) # => 10001
transform(28) # => 11100
```

The names we want to generate need to be in the range `'AA000'..'ZZ999'`. That is to say, the last three characters need to be 0-9 (base 10), while the first two characters need to be A-Z (base 26). Modifying our function to accommodate this is straightforward enough:

```ruby
def transform(number)
  name = []

  name << number % 10
  number = number / 10

  name << number % 10
  number = number / 10

  name << number % 10
  number = number / 10

  name << char(number % 26)
  number = number / 26

  name << char(number % 26)
  number = number / 26

  name.reverse.join
end

def char(number)
  (65 + number).chr
end

transform(0) # => AA000
transform(1) # => AA001
```

If we clean this up a bit, then we end up with the following code:

```ruby
def generate_name(number)
  name = []

  3.times do
    name << number % 10
    number = number / 10
  end

  2.times do
    name << char(number % 26)
    number = number / 26
  end

  name.reverse.join
end

def char(number)
  (65 + number).chr
end
```

There we go, that was pretty easy. The first of our subproblems has been solved and we're now halfway to solving our robot naming problem. Let's go ahead and take a look at the second subproblem: creating a custom random number generator.


### Creating a custom random number generator

Creating a random number generator that returns all numbers in a given range exactly once in a random order is a bit of an unusual programming problem. Thinking back to my CS classes, I can vaguely remember a lecture about generating pseudo-random numbers with a linear congruential generator. So let's start by having a look at [its Wikipedia page](https://en.wikipedia.org/wiki/Linear_congruential_generator).

Linear congruential generators use the following formula to generate random numbers:

>next_random_number = (a * current_random_number + c) % m

A generator will have different properties depending on the choice of the `a`, `c`, and `m` parameters. Luckily for us, there is [a small section on its wiki page](https://en.wikipedia.org/wiki/Linear_congruential_generator#c%E2%89%A00]) that describes how these parameters should be chosen in order for a generator to return all numbers of a given range exactly once in a random order.

If our range is a power of 2, these parameters need to fulfill the following requirements:

- `m` will be our range, and therefore needs to be a power of 2
- `a` needs to be smaller than `m` and `a - 1` needs to be divisible by 4
- `c` can be any odd number smaller than `m`

Writing a generator that meets these requirements is a pretty straightforward undertaking:

```ruby
class Generator
  def initialize(range:)
    @range = range
    init_rng
  end

  def reset
    init_rng
  end

  def next
    @r = ((@a * @r) + @c) % @m
  end

  private

  def init_rng
    random = Random.new

    # m needs to be a power of two for now (we don't support arbitrary ranges yet)]
    # a needs to be smaller than m and (a - 1) needs to be divisible by 4
    # c can be any odd number smaller than m
    @m = @range
    @a = random.rand(@m / 4).to_i * 4 + 1
    @c = random.rand(@m / 2).to_i * 2 + 1

    # a random seed to get our generator started. The value of this seed needs to be
    # smaller than the value of m as well.
    @r = random.rand(@m).to_i
  end
end

# remember that our range needs to be a power of 2 for now
gen = Generator.new(range: 8)
16.times.map { gen.next }
# => [6, 1, 4, 7, 2, 5, 0, 3, 6, 1, 4, 7, 2, 5, 0, 3]

gen.reset
16.times.map { gen.next }
# => [2, 3, 0, 1, 6, 7, 4, 5, 2, 3, 0, 1, 6, 7, 4, 5]
```

Note that our generator will start repeating itself after having iterated across all elements in its range. We can fix this by having our `next` method raise an exception when its random numbers start repeating. The code for this can be seen below.

```ruby
class GeneratorExhausted < StandardError; end

class Generator
  ...

  def next
    @r = ((@a * @r) + @c) % @m
    raise GeneratorExhausted if @r == @first_value
    @first_value ||= @r
    @r
  end

  ...
end
```

Note that up until now our range has always needed to be a power of two. Luckily we can easily accommodate ranges of arbitrary length. All we need to do is:

- calculate the first power of two larger than our arbitrary range
- use this power of two for our random number calculations
- if our random number generator comes up with a number outside the specified range, then just throw it away and keep generating numbers until we find one that's inside our range. On average, the very next randomly generated number will be inside the range, so the overhead for this is small. The code for doing so is shown here:


```ruby
class GeneratorExhausted < StandardError; end

class Generator
  def initialize(range:)
    @range = range
    init_rng
  end

  def reset
    init_rng
  end

  def next
    loop do
      @r = ((@a * @r) + @c) % @m
      raise GeneratorExhausted if @r == @first_value

      if @r < @range
        @first_value ||= @r
        return @r
      end
    end
  end

  private

  def init_rng
    random = Random.new

    # m is the first power of two larger than our range
    # a needs to be smaller than m and (a - 1) needs to be divisible by 4
    # c can be any odd number smaller than m
    @m = 2 ** Math.log(@range + 1, 2).ceil
    @a = random.rand(@m / 4).to_i * 4 + 1
    @c = random.rand(@m / 2).to_i * 2 + 1

    # a random seed to get our generator started. The value of this seed needs to be
    # smaller than the value of m as well.
    @r = random.rand(@m).to_i
  end
end

gen = Generator.new(range: 10)
10.times.map { gen.next }
# => [6, 1, 8, 5, 9, 0, 3, 2, 4, 7]
```

The above code solves our second subproblem. We have successfully created a random number generator that'll return all elements in a specified range exactly once in a random order. With both subproblems solved, we can now go ahead and write a solution to the original problem of generating random names for our robots.


### Putting it all together

Our final `NameGenerator` class will end up looking something like shown below. Note that I did not bother to copy the code for the `Generator` class from the previous section.

```ruby
class NameGenerator
  RANGE = 10 * 10 * 10 * 26 * 26

  def initialize
    @generator = Generator.new(range: RANGE)
  end

  def reset
    @generator.reset
  end

  def next
    number = @generator.next
    generate_name(number)
  end

  private

  def generate_name(number)
    name = []

    3.times do
      name << number % 10
      number = number / 10
    end

    2.times do
      name << char(number % 26)
      number = number / 26
    end

    name.reverse.join
  end

  def char(number)
    (65 + number).chr
  end
end

name_generator = NameGenerator.new
name_generator.next # => MJ650
name_generator.next # => HK923
```

The really nice thing about this approach is that by writing our own random number generator we have essentially created a lazily evaluated pseudo-random shuffle. It's the kind of thing you would never want to use in a library that requires proper random numbers (e.g. encryption), but works great for problems like this.

Because of the lazily evaluated nature of our solution, we can now generate names across arbitrarily large ranges. Remember how it used to take 133 seconds to generate the first random name in the range `'AAAA000'..'ZZZZ999'`? We can now do this in just 0.1 seconds! That's a pretty good speed improvement for generating robot names!

Finishing up, I would just like to mention that this was a bit of a weird article for me to write. I'm not really at home with creating random number generators, so there is a real chance that some bugs might have crept in here or there. As always, if you think I got anything wrong, please feel free to get in touch and let me know.