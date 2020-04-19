module Jekyll
  module VueAssetFilter

    def vue_asset(file_name, dir_name=nil)
      if dir_name.nil? # => guess dirname
        if file_name.include? ".js"
          dir_name = "./dist/js/"
        elsif file_name.include? ".css"
          dir_name = "./dist/css/"
        else
          dir_name = "./dist/img/"
        end
      end
      js_file_regexp = Regexp.new("^#{file_name}$".gsub(".","\\..+\\."))
      js_file_name_with_hash = Dir.entries(dir_name).filter {|x| js_file_regexp.match(x) }[0]
      "#{dir_name.gsub(".","")}#{js_file_name_with_hash}"
    end
  end
end

# {{ "app.js" | vue_asset_file }}

Liquid::Template.register_filter(Jekyll::VueAssetFilter)
