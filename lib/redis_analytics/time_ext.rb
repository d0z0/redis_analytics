module TimeExtensions
  %w[ round floor ceil ].each do |_method|
    define_method _method do |*args|
      seconds = args.first || 60
      Time.at((self.to_f / seconds).send(_method) * seconds)
    end
  end

  def end_of_hour
    Time.local(self.year, self.mon, self.day, self.hour, 59, 59)
  end

  def beginning_of_hour
    Time.local(self.year, self.mon, self.day, self.hour, 0, 0)
  end

  def end_of_minute
    Time.local(self.year, self.mon, self.day, self.hour, self.min, 59)
  end

  def beginning_of_minute
    Time.local(self.year, self.mon, self.day, self.hour, self.min, 0)
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

