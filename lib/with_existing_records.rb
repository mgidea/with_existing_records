module WithExistingRecords
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # defines a method to override the generated method from an accepts_nested_attributes_for declaration to take into account
    # when attempting to add existing records onto a collection association.  This method checks for the #{association_name}_attributes
    # in params hash and then uses #{association_name}_ids as with the given ids to add them as a collections and then iterates through
    # the model.#{association_name} collection and assigns the model of each association to the parent object.  This then lets
    # nested_attributes run its course on save and update.  It is best to run save in an ActiveRecord transaction to keep the
    # integrity of the objects.  The method also checks to see if the associated object has been deleted on the form as opposed to
    # marked for destruction.
    #
    # Class User < ActiveRecord::Base
    #
    #   has_many :addresses, :inverse_of => :user
    #   accepts_nested_attributes_for :addresses
    #   add_existing_records_to_nested_attributes_for :addresses
    #    - or - more simply -
    #   nested_attributes_with_existing_records_for(:addresses)
    # end
    #
    # Class Address < ActiveRecord::Base
    # belongs_to :user, :inverse_of => :addresess
    #
    cattr_accessor :with_existing_records, :with_existing_records_defined
    self.with_existing_records ||= []
    self.with_existing_records_defined ||= false
    def add_existing_records_to_nested_attributes_for(*args)
      self.with_existing_records = (self.with_existing_records + args).uniq
      if !with_existing_records_defined
        define_method :assign_nested_attributes_for_collection_association do |association_name, attributes_collection|
          self.class.with_existing_records_defined = true
          self.class.with_existing_records.select!{|arg| self.class.reflections.keys.include?(arg.to_s)}
          if self.class.with_existing_records.include?(association_name)
            self.send("#{association_name.to_s.singularize}_ids=", association_ids(attributes_collection, self.class.reflections[association_name.to_s].klass))
            self.send(association_name).map {|associate| associate.send("#{self.class.reflections[association_name.to_s].inverse_of.name}=", self)}
          end
          super(association_name, attributes_collection)
        end
      end
    end

    # sugar so you don't have to call two methods
    def nested_attributes_with_existing_records_for(*args)
      existing_args = args.last.is_a?(Hash) ? args[0...-1] : args.dup
      accepts_nested_attributes_for *args
      add_existing_records_to_nested_attributes_for *existing_args
    end
  end

  private
  def indexed_hash?(collection)
    !collection.keys.include?("id")
  end

  # find the value of "id" keys from #{association_name}_attributes key in params hash
  def association_ids(collection, klass)
    (indexed_hash?(collection) ? collection.values : [collection]).map do |hash|
      association_id = hash.select{|key, val| key == "id"}.values.first.presence # turn any empty strings into nils
      keep_or_remove_by_id(collection, association_id, klass)
    end
  end

  # remove association from collection so it will not attempt to be assigned if it has been deleted from db during process
  # or collect id so it can be added to #{association_name}_ids array
  def keep_or_remove_by_id(collection, association_id, klass)
    klass.find_by_id(association_id) ? association_id : reject_id(collection, association_id)
  end

  # reject hash associated with a deleted id, always return nil so only valid ids are added to #{association_name}_ids array
  def reject_id(collection, association_id)
    indexed_hash?(collection) ? collection.reject!{|index, attrs| attrs["id"] == association_id} : collection.reject!{|attrs| attrs["id"] == association_id}
    nil
  end
end

ActiveRecord::Base.send :include, WithExistingRecords
