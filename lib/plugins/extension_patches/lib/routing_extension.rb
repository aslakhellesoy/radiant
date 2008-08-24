module Radiant
  module RoutingExtension
  
    def self.included(base)
      base.class_eval do
        alias :draw_without_plugin_routes :draw
        alias :draw :draw_with_plugin_routes
      end
    end
  
    def draw_with_plugin_routes
      begin
        draw_without_plugin_routes do |mapper|
          add_extension_routes(mapper)
          yield mapper
        end
      rescue => e
        # Some extensions fail during bootstrapping. That's usually ok.
        STDERR.puts("WARNING: #{e.message} (You may ignore this if you are running rake db:bootstrap. You may be using a bootstrap-brittle extension...)")
      end
    end

    private
  
      def add_extension_routes(mapper)
        Extension.descendants.each do |ext|
          ext.route_definitions.each do |block|
            block.call(mapper)
          end
        end
      end
    
  end
end

ActionController::Routing::RouteSet.class_eval { include Radiant::RoutingExtension }