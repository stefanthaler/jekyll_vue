require 'fileutils'

# TODO get asset dir from vue config js
# TODO failsafe if some folders are not existing

module Jekyll
  module VueAssetFilter

    def vue_asset(file_name, dir_name=nil)
      if dir_name.nil? # => guess dirname
        if file_name.include? ".js"
          dir_name = "./assets/vue/js/"
        elsif file_name.include? ".css"
          dir_name = "./assets/vue/css/"
        else
          dir_name = "./assets/vue/img/"
        end
      end
      js_file_regexp = Regexp.new("^#{file_name}$".gsub(".","\\..+\\."))
      js_file_name_with_hash = Dir.entries(dir_name).filter {|x| js_file_regexp.match(x) }[0]
      "#{dir_name.gsub(".","")}#{js_file_name_with_hash}"
    end
  end

  class RenderVueHeadTag < Liquid::Tag

    def initialize(tag_name,text, tokens)
      super
    end

    def render(context)
      out_tag = ""
      # prefetch everything except for app and junk vendors
      Dir.entries("./assets/vue/js").each do |js_file|
        next if (js_file=="." or js_file==".." or js_file.include? ".map")

        if js_file.include? "app." or js_file.include? "chunk-vendors."
          out_tag += "<link href='/assets/vue/js/#{js_file}' rel='preload' as='script'>\n"
        else
          out_tag += "<link href='/assets/vue/js/#{js_file}' rel='prefetch' as='script'>\n"
        end
      end

      if File.exist?("./assets/vue/css")
        Dir.entries("./assets/vue/css").each do |css_file|
            next if css_file =="." or css_file==".."
            out_tag +=  "<link href='/assets/vue/css/#{css_file}' rel='preload' as='style'>\n"
            out_tag +=  "<link href='/assets/vue/css/#{css_file}' rel='stylesheet'>\n"
        end
      end
      out_tag
    end
  end

  class RenderVueBodyTag < Liquid::Tag

    def initialize(tag_name,text, tokens)
      super
    end

    def render(context)
      out_tag = ""
      Dir.entries("./assets/vue/js").each do |js_file|
        next if js_file =="." or js_file==".." or js_file.include? ".map"
        if js_file.include? "app." or js_file.include? "chunk-vendors."
          out_tag += "<script src='/assets/vue/js/#{js_file}' ></script>\n"
        end
      end
      out_tag
    end
  end
end


Liquid::Template.register_tag('render_vue_head_includes', Jekyll::RenderVueHeadTag)
Liquid::Template.register_tag('render_vue_body_includes', Jekyll::RenderVueBodyTag)
Liquid::Template.register_filter(Jekyll::VueAssetFilter)


Jekyll::Hooks.register :site, :after_init do |site|
  # call yarn build

  yarn_out = `yarn build`
  exit_code = `echo $?`
  if exit_code.to_i != 0
    puts exit_code
    puts yarn_out # TODO use logging facility
    raise 'Yarn build failed'
  end

  # delete old assets/img folder (only works on )
  #files = Dir.entries("").filter! {|x| x == "." || x =='.." }
  #FileUtils.rm_f(files.each{|d| "./assets/img/#{d}"}) if files
  FileUtils.rm_rf("assets/vue/") if File.exist?("assets/vue")

  # move img to img
  FileUtils.mv('vue-app/assets/vue/','assets/')

end

Jekyll::Hooks.register :site, :after_init do |site|
  if !File.exist?("vue.config.js")
    File.write("vue.config.js", "module.exports = {\noutputDir:'vue-app',\n  assetsDir:'assets/vue'\n}")
  end
end
