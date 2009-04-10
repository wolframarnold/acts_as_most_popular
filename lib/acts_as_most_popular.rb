module ActsAsMostPopular

  def self.included(base)
    base.class_eval do
      self.extend ClassMethods
      include InstanceMethods
      # TODO: Add after_add, after_remove hooks to association reflection
      cattr_accessor :aamp_activity_assn,  :aamp_assn_primary_key_name,
              :aamp_activity_class, :aamp_limit, :aamp_db_finder_args
    end
  end

  module ClassMethods
    def acts_as_most_popular(arg_hash)
      self.aamp_activity_assn = arg_hash[:activity_association]
      assn_reflection = reflect_on_association(self.aamp_activity_assn)
      self.aamp_assn_primary_key_name = assn_reflection.primary_key_name
      self.aamp_activity_class = assn_reflection.klass
      self.aamp_limit = arg_hash[:limit]
      self.aamp_db_finder_args = arg_hash[:db_finder_args]
      set_association_callbacks(:after_add, :incr_activity_count)
      set_association_callbacks(:after_remove, :decr_activity_count)
    end

    def set_association_callbacks(hook, method)
      assn_options = reflect_on_association(self.aamp_activity_assn).options
      case assn_options[hook]
      when nil
        assn_options[hook] = method
      when Array
        assn_options[hook] << method
      else
        assn_options[hook] = [assn_options[hook], method]
      end
    end

    def most_popular
      activity_count_index = repository.get_multi(activity_index_keys)
      if activity_count_index.empty?
        viewable_ids_activity_count_ordered = store_activity_count_index
        return [] if viewable_ids_activity_count_ordered.empty?
        viewable_ids = viewable_ids_activity_count_ordered.map{|vid_ct| vid_ct[0]}
      else
        viewable_ids = index_to_array(activity_count_index).map{|entry| entry[1]}
        # TODO: Handle case where there are fewer than limit data points (viewables)
      end
      viewable_ids.map do |viewable_id|
        find(viewable_id)  # note cannot use find([...]) because that doesn't keep results in same order as indices passed in
      end
    end

    def activity_index_keys
      keys = []
      self.aamp_limit.times do |i|
        keys << cache_key("activity_count_index/#{i}")
      end
      keys
    end

    # Index consists of entries such as: key, viewable_id, activity_count, where key is 0, 1, ... indicating sort order
    def store_activity_count_index
      viewable_ids_activity_count_ordered =
        self.aamp_activity_class.send(:all,
                                      self.aamp_db_finder_args.merge(:order => 'activity_count DESC',
                                                                     :limit => self.aamp_limit))
      retval = []
      viewable_ids_activity_count_ordered.each_with_index do |vid_ct, i|
        entry = [vid_ct.send(self.aamp_assn_primary_key_name),vid_ct.activity_count.to_i]
        retval << entry
        set("activity_count_index/#{i}", entry)
      end
      retval
    end

    def index_to_array(index_from_cache)
      activity_index_keys.map do |cache_key|
        cache_key =~ %r{/(\d+)\Z}
        [$1.to_i] + index_from_cache[cache_key].map(&:to_i)
      end
    end

    def resort_activity_count_index(index)
      activity_count_index = index.sort{|a,b| b[2] <=> a[2]}  # TODO: don't just assume descending order, make it configurable
      activity_count_index.each_with_index do |key_id_ct, i|
        set("activity_count_index/#{i}", key_id_ct[1..2])
      end
    end
  end

  module InstanceMethods
    def incr_activity_count(activity)
      p 'called'
      base_class = self.class.base_class
      activity_count_index = base_class.repository.get_multi(base_class.activity_index_keys)
      return if activity_count_index.empty?
      activity_count_index = base_class.index_to_array(activity_count_index)
      indexed = activity_count_index.find{|idx_id_ct| idx_id_ct[1] == self.id}
      if indexed.nil?
        new_activity_count = self.send(base_class.aamp_activity_assn).count
        if new_activity_count - 1 > activity_count_index.last[2]
          # Item wasn't indexed before, but now is -> bumped a lower one off
          base_class.set("activity_count_index/#{base_class.aamp_limit-1}", [self.id, new_activity_count])
          activity_count_index[base_class.aamp_limit-1][1..2] = [self.id, new_activity_count]
          base_class.resort_activity_count_index(activity_count_index)
        end
      else
        new_activity_count = indexed[2] + 1
        idx = indexed[0]
        base_class.set("activity_count_index/#{idx}", [self.id, new_activity_count])
        if idx > 0 && new_activity_count > activity_count_index[idx-1][2]
          activity_count_index[idx][1..2] = [self.id, new_activity_count]
          base_class.resort_activity_count_index(activity_count_index)
        end
      end
    end
    private :incr_activity_count
    # TODO: handle decrement case (not as common, as activities rarely get deleted)
    def decr_activity_count(activity)
    end
    private :decr_activity_count
  end
end
