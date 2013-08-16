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
        raise ArgumentError if !_has_tally(attribute, by)

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
      unless new_callbacks?
        model.before(:delete, :_decrement_tallies)
        model.before(:save, :_decrement_tallies)
        model.after(:save, :_increment_tallies)
      end
      model.extend(Macros)
    end

    private
    def self.new_callbacks?
      Ohm::Callbacks.protected_instance_methods.include?(:before_save)
    end

    protected
    def _decrement_tallies
      _update_tallies(-1) do |attribute|
        if respond_to? :read_remote
          read_remote(attribute)
        else
          # ugly, but better than using get and having
          # to save and restore the old value
          db.hget(key, attribute)
        end
      end
    end

    def _increment_tallies
      _update_tallies(1) { |attribute| send(attribute) }
    end

    def _update_tallies(amount, &block)
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

    if new_callbacks?
      def before_delete
        _decrement_tallies
      end

      def before_update
        _decrement_tallies
      end

      def after_save
        _increment_tallies
      end
    end
  end
end
