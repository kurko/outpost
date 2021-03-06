module Outpost
  class DSL
    class << self
      attr_reader :scouts

      def using(scouts, &block)
        @scouts ||= Hash.new { |h, k| h[k] = {} }

        config = ScoutConfig.new
        config.instance_eval(&block)

        scouts.each do |scout, description|
          @scouts[scout][:description] = description
          @scouts[scout][:config]      = config
        end
      end
    end

    attr_reader :last_status, :reports

    def run
      @reports = self.class.scouts.map do |scout, options|
        run_scout(scout, options)
      end

      statuses = @reports.map { |r| r.status }

      @last_status = Report.summarize(statuses)
    end

    def up?
      @last_status == :up
    end

    def down?
      @last_status == :down
    end

    def messages
      reports.map { |r| r.to_s }
    end

    def run_scout(scout, options)
      scout_instance = scout.new(options[:description], options[:config])

      params = {
        :name        => scout.name,
        :description => options[:description],
        :status      => scout_instance.run
      }
      Report.new(params)
    end
  end
end
