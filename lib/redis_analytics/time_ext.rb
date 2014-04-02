module TimeExtensions
  %w[ round floor ceil ].each do |_method|
    define_method _method do |*args|
      seconds = args.first || 60
      Time.at((self.to_f / seconds).send(_method) * seconds)
    end
  end

  def end_of_hour
    change(:min => 59, :sec => 59, :usec => 999999.999)
  end

  def beginning_of_hour(seconds = 60)
    change(:min => 0, :sec => 0, :usec => 0)
  end

  def end_of_minute
    change(:sec => 59, :usec => 999999.999)
  end

  def beginning_of_minute
    change(:sec => 0, :usec => 0)
  end
end

Time.send :include, TimeExtensions

module FixnumExtensions

  def minute
    self * 60
  end

  def hour
    minute * 60
  end

  def day
    hour * 24
  end

  def week
    day * 7
  end

  def month
    day * 30 
  end

  def year
    day * 365
  end

  def ago(time = Time.now)
    time - self
  end
end

Fixnum.send :include, FixnumExtensions

