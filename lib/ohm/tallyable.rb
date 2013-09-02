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

      def retally(attribute)
        raise ArgumentError unless tallies.include?(attribute)
        keys = _tally_keys(attribute)
        db.del(*keys) unless keys.empty?
        all.each { |e| e.send(:_increment_tallies) }
        nil
      end

      def leaderboard(attribute, by=nil)
        raise ArgumentError unless _has_tally(attribute, by)

        _load_zset(_tally_key(attribute, by))
          .map { |k, v| [k, v.to_i] }
          .sort_by { |k, v| [-v, k] }
      end

      def _has_tally(attribute, by=nil)
        tally = tallies[attribute]
        !!(tally && (!tally[:by] || (by && by.include?(tally[:by]))))
      end

      def _tally_key(attribute, by=nil)
        key = self.key[:tallies][attribute]
        if by
          key = key[by.keys.first][by.values.first]
        end
        key
      end

      def _tally_keys(attribute)
        keys = db.keys(_tally_key(attribute))
        keys.concat(db.keys(_tally_key(attribute)["*"]))
      end

      if Redis::VERSION.to_i >= 3
        def _load_zset(key)
          key.zrevrange(0, -1, with_scores: true)
        end
      else
        def _load_zset(key)
          key.zrevrange(0, -1, with_scores: true).each_slice(2)
        end
      end
    end

    if Ohm::Contrib::VERSION.to_i >= 1
      def self.included(model)
        model.extend(Macros)
      end

      def before_delete
        _decrement_tallies
        super
      end
      protected :before_delete

      def before_update
        _decrement_tallies
        super
      end
      protected :before_update

      def after_save
        _increment_tallies
        super
      end
      protected :after_save

    else
      def self.included(model)
        model.before(:delete, :_decrement_tallies)
        model.before(:save, :_decrement_tallies)
        model.after(:save, :_increment_tallies)

        model.extend(Macros)
      end
    end

  protected
    def _decrement_tallies
      _update_tallies(-1) { |attribute| db.hget(key, attribute) }
    end

    def _increment_tallies
      _update_tallies(1) { |attribute| send(attribute) }
    end

    def _update_tallies(amount, &block)
      return if new?

      self.class.tallies.each do |attribute, options|
        by = options[:by] ? {options[:by] => yield(options[:by])} : nil
        key = self.class._tally_key(attribute, by)

        if (value = yield(attribute))
          key.zincrby(amount, value)
          # need to convert zscore to_i because older versions
          # return a double encoded in a string
          key.zrem(value) if key.zscore(value).to_i == 0
        end
      end
    end
  end
end
