require 'sparkle_formation'

class SparkleFormation

  # Provides template helper methods
  module SparkleAttribute

    # Fn::Join generator
    #
    # @param args [Object]
    # @return [Hash]
    def _cf_join(*args)
      options = args.detect{|i| i.is_a?(Hash) && i[:options]} || {:options => {}}
      args.delete(options)
      unless(args.size == 1)
        args = [args]
      end
      {'Fn::Join' => [options[:options][:delimiter] || '', *args]}
    end
    alias_method :join!, :_cf_join

    # Ref generator
    #
    # @param thing [String, Symbol] reference name
    # @return [Hash]
    # @note Symbol value will force key processing
    def _cf_ref(thing)
      thing = _process_key(thing, :force) if thing.is_a?(Symbol)
      {'Ref' => thing}
    end
    alias_method :_ref, :_cf_ref
    alias_method :ref!, :_cf_ref

    # Fn::FindInMap generator
    #
    # @param thing [String, Symbol] thing to find
    # @param key [String, Symbol] thing to search
    # @param suffix [Object] additional args
    # @return [Hash]
    def _cf_map(thing, key, *suffix)
      suffix = suffix.map do |item|
        if(item.is_a?(Symbol))
          _process_key(item, :force)
        else
          item
        end
      end
      thing = _process_key(thing, :force) if thing.is_a?(Symbol)
      if(key.is_a?(Symbol))
        key = ref!(key)
      end
      {'Fn::FindInMap' => [thing, key, *suffix]}
    end
    alias_method :_cf_find_in_map, :_cf_map
    alias_method :find_in_map!, :_cf_map
    alias_method :map!, :_cf_map

    # Fn::GetAtt generator
    #
    # @param [Object] pass through arguments
    # @return [Hash]
    def _cf_attr(*args)
      args = args.map do |thing|
        if(thing.is_a?(Symbol))
          _process_key(thing, :force)
        else
          thing
        end

      end
      {'Fn::GetAtt' => args}
    end
    alias_method :_cf_get_att, :_cf_attr
    alias_method :get_att!, :_cf_attr
    alias_method :attr!, :_cf_attr

    # Fn::Base64 generator
    #
    # @param arg [Object] pass through
    # @return [Hash]
    def _cf_base64(arg)
      {'Fn::Base64' => arg}
    end
    alias_method :base64!, :_cf_base64

    # Fn::GetAZs generator
    #
    # @param region [String, Symbol] String will pass through. Symbol will be converted to ref
    # @return [Hash]
    def _cf_get_azs(region=nil)
      region = case region
               when Symbol
                 _cf_ref(region)
               when NilClass
                 ''
               else
                 region
               end
      {'Fn::GetAZs' => region}
    end
    alias_method :get_azs!, :_cf_get_azs
    alias_method :azs!, :_cf_get_azs

    # Fn::Select generator
    #
    # @param index [String, Symbol, Integer] Symbol will be converted to ref
    # @param item [Object, Symbol] Symbol will be converted to ref
    # @return [Hash]
    def _cf_select(index, item)
      index = index.is_a?(Symbol) ? _cf_ref(index) : index
      item = _cf_ref(item) if item.is_a?(Symbol)
      {'Fn::Select' => [index, item]}
    end
    alias_method :select!, :_cf_select

    # Condition generator
    #
    # @param name [String, Symbol] symbol will be processed
    # @return [Hash]
    def _condition(name)
      {'Condition' => name.is_a?(Symbol) ? _process_key(name) : name}
    end
    alias_method :condition!, :_condition

    # Condition setter
    #
    # @param name [String, Symbol] condition name
    # @return [SparkleStruct]
    # @note this is used to set a {"Condition" => "Name"} into the
    #   current context, generally the top level of a resource
    def _on_condition(name)
      _set(*_condition(name).to_a.flatten)
    end
    alias_method :on_condition!, :_on_condition

    # Fn::If generator
    #
    # @param cond [String, Symbol] symbol will be case processed
    # @param true_value [Object]
    # @param false_value [Object]
    # @return [Hash]
    def _if(cond, true_value, false_value)
      cond = cond.is_a?(Symbol) ? _process_key(cond) : cond
      {'Fn::If' => _array(cond, true_value, false_value)}
    end
    alias_method :if!, :_if

    # Fn::And generator
    #
    # @param args [Object]
    # @return [Hash]
    # @note symbols will be processed and set as condition. strings
    #   will be set as condition directly. procs will be evaluated
    def _and(*args)
      {
        'Fn::And' => _array(
          *args.map{|v|
            if(v.is_a?(Symbol) || v.is_a?(String))
              _condition(v)
            else
              v
            end
          }
        )
      }
    end
    alias_method :and!, :_and

    # Fn::Equals generator
    #
    # @param v1 [Object]
    # @param v2 [Object]
    # @return [Hash]
    def _equals(v1, v2)
      {'Fn::Equals' => _array(v1, v2)}
    end
    alias_method :equals!, :_equals

    # Fn::Not generator
    #
    # @param arg [Object]
    # @return [Hash]
    def _not(arg)
      if(arg.is_a?(String) || arg.is_a?(Symbol))
        arg = _condition(arg)
      else
        arg = _array(arg).first
      end
      {'Fn::Not' => [arg]}
    end
    alias_method :not!, :_not

    # Fn::Or generator
    #
    # @param v1 [Object]
    # @param v2 [Object]
    # @return [Hash]
    def _or(*args)
      {
        'Fn::Or' => _array(
          *args.map{|v|
            if(v.is_a?(Symbol) || v.is_a?(String))
              _condition(v)
            else
              v
            end
          }
        )
      }
    end
    alias_method :or!, :_or

    # No value generator
    #
    # @return [String]
    def _no_value
      _ref('AWS::NoValue')
    end
    alias_method :no_value!, :_no_value

    # Region generator
    #
    # @return [Hash]
    def _region
      _ref('AWS::Region')
    end
    alias_method :region!, :_region

    # Notification ARNs generator
    #
    # @return [Hash]
    def _notification_arns
      _ref('AWS::NotificationARNs')
    end
    alias_method :notification_arns!, :_notification_arns

    # Account ID generator
    #
    # @return [Hash]
    def _account_id
      _ref('AWS::AccountId')
    end
    alias_method :account_id!, :_account_id

    # Stack ID generator
    #
    # @return [Hash]
    def _stack_id
      _ref('AWS::StackId')
    end
    alias_method :stack_id!, :_stack_id

    # Stack name generator
    #
    # @return [Hash]
    def _stack_name
      _ref('AWS::StackName')
    end
    alias_method :stack_name!, :_stack_name

    # Resource dependency generator
    #
    # @param [Symbol, String, Array<Symbol, String>] resource names
    # @return [Array<String>]
    def _depends_on(*args)
      _set('DependsOn', [args].flatten.compact.map{|s| _process_key(s)})
    end
    alias_method :depends_on!, :_depends_on

    # Reference output value from nested stack
    #
    # @param stack_name [String, Symbol] logical resource name of stack
    # @apram output_name [String, Symbol] stack output name
    def _stack_output(stack_name, output_name)
      _cf_attr(_process_key(stack_name), "Outputs.#{_process_key(output_name)}")
    end
    alias_method :stack_output!, :_stack_output

    # Execute system command
    #
    # @param command [String]
    # @return [String] result
    def _system(command)
      ::Kernel.send('`', command)
    end
    alias_method :system!, :_system

    # Print to stdout
    #
    # @param args
    # @return [NilClass]
    def _puts(*args)
      $stdout.puts(*args)
    end
    alias_method :puts!, :_puts

    # Raise an exception
    def _raise(*args)
      ::Kernel.raise(*args)
    end
    alias_method :raise!, :_raise

    # @return [TrueClass, FalseClass] resource can be tagged
    def taggable?
      if(defined?(SfnAws))
        if(self[:type])
          resource = SfnAws.lookup(self[:type].gsub('::', '_').downcase)
          resource && resource[:properties].include?('Tags')
        else
          if(self._parent)
            self._parent.taggable?
          end
        end
      end
    end

    # @return [TrueClass, FalseClass]
    def rhel?
      !!@platform[:rhel]
    end

    # @return [TrueClass, FalseClass]
    def debian?
      !!@platform[:debian]
    end

    # Set the destination platform
    #
    # @param plat [String, Symbol] one of :rhel or :debian
    # @return [TrueClass]
    def _platform=(plat)
      @platform || __hashish
      @platform.clear
      @platform[plat.to_sym] = true
    end

    # Dynamic insertion helper method
    #
    # @param name [String, Symbol] dynamic name
    # @param args [Object] argument list for dynamic
    # @return [self]
    def dynamic!(name, *args, &block)
      SparkleFormation.insert(name, self, *args, &block)
    end

    # Registry insertion helper method
    #
    # @param name [String, Symbol] name of registry item
    # @param args [Object] argument list for registry
    # @return [self]
    def registry!(name, *args)
      SparkleFormation.registry(name, self, *args)
    end

    # Stack nesting helper method
    #
    # @param template [String, Symbol] template to nest
    # @param args [String, Symbol] stringified and underscore joined for name
    # @return [self]
    def nest!(template, *args, &block)
      SparkleFormation.nest(template, self, *args, &block)
    end

  end
end
