require 'ohm'
require 'ohm/contrib'

module Ohm
  module Tallyable
    module Macros
      def tally(attribute, options={})
        tallies[attribute] = options
      end

      def tallies
        @tallies ||= {}
      end

      def leaderboard(attribute, by=nil)
        tally = tallies[attribute]
        if tally.nil? || (tally[:by] && (by.nil? || !by.include?(tally[:by])))
          raise ArgumentError
        end
        key = self.key[:tallies][attribute]
        if by
          key = key[by.keys.first][by.values.first]
        end

        _load_zset(key)
          .map { |k, v| [k, v.to_i] }
          .sort_by { |k, v| [-v, k] }
      end

      if Redis::VERSION.to_i == 2
        def _load_zset(key)
          key.zrevrange(0, -1, with_scores: true).each_slice(2)
        end
      else
        def _load_zset(key)
          key.zrevrange(0, -1, with_scores: true)
        end
      end
    end

    def self.included(model)
      model.before(:delete, :_decrement_tallies)
      model.before(:save, :_decrement_tallies)
      model.after(:save, :_increment_tallies)

      model.extend(Macros)
    end

    def _decrement_tallies
      _update_tallies(-1) { |attribute| read_remote(attribute) }
    end

    def _increment_tallies
      _update_tallies(1) { |attribute| send(attribute) }
    end

    def _update_tallies(amount, &block)
      self.class.tallies.each do |attribute, options|
        value = yield(attribute)
        key = self.class.key[:tallies][attribute]
        if options[:by]
          value_by = yield(options[:by])
          key = key[options[:by]][value_by]
        end
        if value
          key.zincrby(amount, value)
          key.zrem(value) if key.zscore(value) == 0.0
        end
      end
    end
  end
end
