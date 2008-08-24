require 'annotatable'
require 'simpleton'
require 'radiant/admin_ui'

module Radiant
  class Extension
    include Simpleton
    include Annotatable

    annotate :version, :description, :url, :root, :extension_name

    attr_writer :active

    def active?
      @active
    end
    
    def migrator
      ExtensionMigrator.new(self)
    end

    def admin
      AdminUI.instance
    end

    def meta
      self.class.meta
    end

    class << self

      def activate_extension
        return if instance.active?
        begin
          instance.activate if instance.respond_to? :activate
          ActionController::Routing::Routes.reload
          instance.active = true
        rescue => e
          # Some extensions fail during bootstrapping. That's usually ok.
          STDERR.puts("WARNING: #{e.message} (You may ignore this if you are running rake db:bootstrap. You may be using a bootstrap-brittle extension...)")
        end
      end
      alias :activate :activate_extension

      def deactivate_extension
        return unless instance.active?
        instance.active = false
        instance.deactivate if instance.respond_to? :deactivate
      end
      alias :deactivate :deactivate_extension

      def define_routes(&block)
        route_definitions << block
      end

      def inherited(subclass)
        subclass.extension_name = subclass.name.to_name('Extension')
      end

      def meta
        Radiant::ExtensionMeta.find_or_create_by_name(extension_name)
      end

      def route_definitions
        @route_definitions ||= []
      end

    end
  end
end
