require 'ohm'
require 'ohm/contrib'

module Ohm
  module Tallyable
    module ClassMethods
      def tally(attribute, options={})
        tallies[attribute] = options
      end

      def tallies
        @tallies ||= {}
      end

      def retally(attribute)
        raise ArgumentError unless tallies.include?(attribute)
        keys = tally_keys(attribute)
        db.del(*keys) unless keys.empty?
        all.each { |e| e.send(:increment_tallies) }
        nil
      end

      def leaderboard(attribute, by=nil)
        raise ArgumentError unless tally_exists?(attribute, by)

        _load_zset(tally_key(attribute, by))
          .map { |k, v| [k, v.to_i] }
          .sort_by { |k, v| [-v, k] }
      end

      def tally_exists?(attribute, by=nil)
        tally = tallies[attribute]
        !!(tally && (!tally[:by] || (by && by.include?(tally[:by]))))
      end

      def tally_key(attribute, by=nil)
        key = self.key[:tallies][attribute]
        if by
          key = key[by.keys.first][by.values.first]
        end
        key
      end

      def tally_keys(attribute)
        keys = db.keys(tally_key(attribute))
        keys.concat(db.keys(tally_key(attribute)["*"]))
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
      protected :_load_zset
    end

    if Ohm::Contrib::VERSION.to_i >= 1
      def self.included(model)
        model.extend(ClassMethods)
      end

      def before_delete
        decrement_tallies
        super
      end
      protected :before_delete

      def before_update
        decrement_tallies
        super
      end
      protected :before_update

      def after_save
        increment_tallies
        super
      end
      protected :after_save

    else
      def self.included(model)
        model.before(:delete, :decrement_tallies)
        model.before(:save, :decrement_tallies)
        model.after(:save, :increment_tallies)

        model.extend(ClassMethods)
      end
    end

  protected
    def decrement_tallies
      update_tallies(-1) { |attribute| db.hget(key, attribute) }
    end

    def increment_tallies
      update_tallies(1) { |attribute| send(attribute) }
    end

    def update_tallies(amount)
      return if new?

      self.class.tallies.each do |attribute, options|
        by = options[:by] ? {options[:by] => yield(options[:by])} : nil
        key = self.class.tally_key(attribute, by)

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
