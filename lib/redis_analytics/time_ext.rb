require  'date'
module TimeExtensions

  def end_of_minute
    Time.local(self.year, self.mon, self.day, self.hour, self.min, 59)
  end

  def beginning_of_minute
    Time.local(self.year, self.mon, self.day, self.hour, self.min, 0)
  end
end

Time.send :include, TimeExtensions
