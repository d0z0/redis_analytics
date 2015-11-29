module RedisAnalytics
  class EventsController < RedisAnalytics::ApplicationController
    include RedisAnalytics::Helpers

    def series
      metrics = params[:metric].split(',')
      to_date_time = Date.parse(params[:to]).to_time rescue Time.now
      units = (params[:count] || 1).to_i
      unit = params[:per] || 'day'
      from_date_time = to_date_time - units.send(unit)
      result = metrics.map do |metric|
        {
          name: metric,
          data: self.send("#{unit}ly_#{metric}", from_date_time, :to_date => to_date_time)
        }
      end
      render json: result
    end

    def aggregate
      metric = params[:metric]
      to_date_time = Date.parse(params[:to]).to_time rescue Time.now
      units = (params[:count] || 1).to_i
      unit = params[:per] || 'day'
      from_date_time = to_date_time - units.send(unit)
      result = self.send("#{unit}ly_#{metric}", from_date_time, :to_date => to_date_time)
      render json: result
    end

  end
end
