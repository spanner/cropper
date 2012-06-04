require 'active_model/validations/numericality'

module Paperclip
  module Validators
    class AttachmentHeightValidator < ActiveModel::Validations::NumericalityValidator
      AVAILABLE_CHECKS = [:less_than, :less_than_or_equal_to, :greater_than, :greater_than_or_equal_to]

      def initialize(options)
        extract_options(options)
        super
      end

      def validate_each(record, attr_name, value)
        attachment = record.send(attr_name)
        dimensions = Paperclip::Geometry.from_file(attachment.queued_for_write[:original])
        value = dimensions.height.to_i
        options.slice(*AVAILABLE_CHECKS).each do |option, option_value|
          option_value = extract_option_value(option, option_value)
          unless value.send(CHECKS[option], option_value)
            error_message_key = options[:in] ? :in_between : option
            record.errors.add(attr_name, error_message_key, filtered_options(value).merge(
              :min => min_value,
              :max => max_value
            ))
          end
        end
      end

      def check_validity!
        unless (AVAILABLE_CHECKS + [:in]).any? { |argument| options.has_key?(argument) }
          raise ArgumentError, "You must pass either :less_than, :greater_than, or :in to the validator"
        end
      end

    private

      def extract_options(options)
        if range = options[:in]
          if !options[:in].respond_to?(:call)
            options[:less_than_or_equal_to] = range.max
            options[:greater_than_or_equal_to] = range.min
          else
            options[:less_than_or_equal_to] = range
            options[:greater_than_or_equal_to] = range
          end
        end
      end

      def extract_option_value(option, option_value)
        if option_value.is_a?(Range)
          if [:less_than, :less_than_or_equal_to].include?(option)
            option_value.max
          else
            option_value.min
          end
        else
          option_value
        end
      end

      def min_value
        value = options[:greater_than_or_equal_to] || options[:greater_than]
        value = value.min if value.respond_to?(:min)
        value
      end

      def max_value
        value = options[:less_than_or_equal_to] || options[:less_than]
        value = value.max if value.respond_to?(:max)
        value
      end
    end

    module HelperMethods
      # Places ActiveRecord-style validations on the pixel height of the file assigned. 
      # The possible options are:
      # * +in+: a Range of bytes (i.e. +1..1.megabyte+),
      # * +less_than+: equivalent to :in => 0..options[:less_than]
      # * +greater_than+: equivalent to :in => options[:greater_than]..Infinity
      # * +message+: error message to display, use :min and :max as replacements
      # * +if+: A lambda or name of an instance method. Validation will only
      #   be run if this lambda or method returns true.
      # * +unless+: Same as +if+ but validates if lambda or method returns false.
      def validates_attachment_height(*attr_names)
        validates_with AttachmentHeightValidator, _merge_attributes(attr_names)
      end
    end
  end
end
