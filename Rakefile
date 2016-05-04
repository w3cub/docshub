#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'json'
require 'nokogiri'
require 'logger'


$debug = false
$docs = nil

devdocs_path = "devdocs"
website_path = "website"
icons_path = "docslogo"

docs_path = "#{devdocs_path}/public/docs/"
stylesheets_path = "#{devdocs_path}/assets/stylesheets/"
sass_path = "#{website_path}/sass/"

docs_image_path = "#{devdocs_path}/assets/images/"
image_target_path = "#{website_path}/source/images/"

docs_generate_target = "#{website_path}/.docs-cache/"
docs_target_path = "#{website_path}/source/_docs/"
json_target_path = "#{website_path}/source/_data/"
json_js_target_path = "#{website_path}/source/json/"

icons_source_path = "#{icons_path}/dist/beauty/72x72/"
icons_target_path = "#{website_path}/source/images/docs/"


credits_path = "#{devdocs_path}/assets/javascripts/templates/pages/about_tmpl.coffee"
credits_regex = /credits\s*=\s*(\[[\s\S]*\])/

$debugTestDocs = "git|grunt|backbone|underscore|bower|typescript"


def del_target(target)
  if Dir[target] != nil
    FileUtils.rm_rf(target)
  end
end

def get_type(slug)
  docs = $docs || ($docs = JSON.parse( IO.read("website/source/_data/docs.json")))
  item = docs.select{ |item| item["slug"] == slug }
  item[0] && item[0]["type"]
end

def fix_doc_link(html, path)
  # puts path
  doc = Nokogiri::HTML(html)
  # fix link
  doc.css("a").each do |link|
    if(link.attributes["href"])
      href = link.attributes["href"].value
      if(!(/^http(s)?/ =~ href))
        if(/^([^#]|\.\.\/)/ =~ href)
          if(!(/\w+\/index\.html/ =~path.sub(Regexp.new("{#docs_generate_target}"), ""))) #  location.pathname != "/" + PageConfig.doctype +"/"
            href = "../" + href
          end
        end
        if (/#/ =~ href)
          href = href.gsub(/(\/[\w-\.]+)#/, '\1/#')
        elsif (!(/\.html$/ =~href))
          href = href + '/'
        end
        link.attributes["href"].value = href
      else
        link.set_attribute('target', '_blank')
      end
    end
  end
  slug = /docs-cache\/([\w~.]+)/.match(path)[1]
  title = doc.css('h1 > text()').text  == ""  ? doc.css('h1').text : doc.css('h1 > text()').text
  robj = {}
  robj[:text] = doc.css('body').inner_html
  robj[:title] = title ? (title.gsub(/[^\w\s\-\:]/," ").strip.downcase + " - #{slug}") : slug
  robj[:slug] = slug
  robj[:isindex] = Regexp.new("#{slug}\/index\.html$") =~ path
  robj[:keywords] = title.strip.downcase.split(/[\/\.\$\s,@:-_`"]+/).push(slug).uniq().reject { |c| c.empty? || ['a', 'and', 'the'].include?(c) }.join(", ")

  robj
end

def handle_file(target)
  # handle file
  slug = /docs-cache\/(\w+)/.match(target)[1] # doc name
  file = IO.read(target)
  doc = fix_doc_link(file, target) # fix link
  type = get_type(doc[:slug])

  # mtitle = doc.match(/<h1[^>]*>([\s\S]*?)<\/h1>/)
  # title = mtitle ? mtitle[1].gsub(/<([a-z]+)[^>]*>([\s\S]*?)<\/\1>/, "").gsub("\\","%5C").gsub("\"","\\\"").strip.downcase : "no title"
  # isindex = Regexp.new("#{slug}\/index\.html$") =~ target

  openfile = open(target, 'w') do |page|
    page.puts "---"
    page.puts "layout: docs"
    page.puts "title: \"#{doc[:title]}\""
    page.puts "keywords: #{doc[:keywords]}"
    page.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M')}"
    page.puts "comments: true"
    page.puts "sharing: true"
    page.puts "footer: true"
    page.puts "slug: #{doc[:slug]}"
    page.puts "type: #{type}"
    page.puts "permalink: " + (doc[:isindex] ?  "/:path.html" : "/:path/")
    page.puts "---\n"
    page << "{% raw %}\n"
    page << doc[:text]
    page << "{% endraw %}"
  end
end

def generate_html(source_path, target_path)
  Dir.glob(source_path + "**/*.html") do |source|
      target = source.sub(/^#{source_path}/, target_path)
      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.copy(source, target)
      puts "handle: " + target
      handle_file(target)
  end
  # Find.find(source_path) do |source|
  #   if File.directory?(source)
  #     # Find.prune if File.basename(source) == '.svn'
  #   else
  #     Find.prune unless /\.html$/ =~ File.basename(source) # filter html only

  #     target = source.sub(/^#{source_path}/, target_path)
  #     FileUtils.mkdir_p(File.dirname(target))
  #     FileUtils.copy(source, target)
  #     puts "handle: " + target
  #     handle_file(target)
  #   end
  # end
end

def copy_html(source_path, target_path, debug=true)
  if debug
    Dir[source_path + "*"].each do |x|
      if debug.kind_of?(Array)
        matchs = Regexp.new("(" + debug.join("|") + ")$" ).match(x)
      else
        matchs = Regexp.new("(" + $debugTestDocs + ")$").match(x)
      end
      if matchs
        tarpath = target_path + matchs[1]
        FileUtils.mkdir_p(tarpath)
        FileUtils.cp_r(x + "/.", tarpath)
      end
    end
  else
    FileUtils.cp_r(source_path + ".", target_path)
  end
end

def copy_json(source_path, target_path, handle_file=nil)
    Dir.glob(source_path + "*/index.json") do |source|
      target = source.sub(/^#{source_path}/, target_path)
      target = target.sub(/(\w+)\/index/, '\1')
      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.copy(source, target)
      handle_file && handle_file.call(target)
    end
end

def get_child_path(path)
  Dir.glob(path + "*")
end


def json_handle(target)
  file = JSON.parse(IO.read(target))
  entries = file["entries"]
  # $logger.info("+ " + target)
  entries.map { |item|
    item["path"] = item["path"]
    .sub(/^index(\/)?/, "")
    .sub(/([^\/\#]+)?(?:#[^\#]+)?$/) do |all|
      if all.include?("#")
        idx = all.index("#").to_i
        if idx > 0
          all.insert(idx, "/")
        else
          all
        end
      else
        all.insert(-1, "/")
      end
    end
    item
  }
  file["entries"] = entries

  openfile = open(target, 'w') do |page|
    page << "app = app || {};\n app.DOC =  "
    page << file.to_json
    page <<";"
  end
  File.rename(target, File.dirname(target) + '/' + File.basename(target, '.json') + '.js')
end


def copy_credits(path, regex, target)
  file = IO.read(path)
  credits_data = regex.match(file)[1]
  data = JSON.parse(eval(credits_data.to_s).to_json)
  IO.write(target + "credits.json", data)
end



desc "Generate docs html"
task :generate_html do |t, args|
  del_target(docs_generate_target)
  generate_html(docs_path, docs_generate_target)
end


desc "Copy docs html to website, if debug param is set, only copy a part of docs"
task :copy_html, :debug do |t, args|
  args.with_defaults(:debug=> true)
  debug = args[:debug]
  del_target(docs_target_path)
  if ["true", "false", true, false].include? debug
    copy_html(docs_generate_target, docs_target_path, (debug == "true" || debug == true))
  else
    if debug.is_a?(String) && debug.match(/(\w+\|?)*?/)
      debug = debug.split("|")
      copy_html(docs_generate_target, docs_target_path, debug)
    end
  end
end


desc "Generate html and copy"
task :gen_copy => [:generate_html, :copy_html] do
end


desc "Copy docs.json to website"
task :copy_index_json do
  filename = "docs.json"
  del_target(json_target_path + filename)
  FileUtils.copy(docs_path + filename, json_target_path)
  puts "Copy docs.json Done"
end


desc "Copy docs credits"
task :copy_credits do 
  filename = "credits.json"
  del_target(json_target_path + filename)
  copy_credits(credits_path, credits_regex, json_target_path)
  puts "Copy docs credits Done"
end


desc "Copy all docs json and changed to javascript `menuJson` Object"
task :copy_json_js do
  del_target(json_js_target_path)
  copy_json(docs_path, json_js_target_path, method(:json_handle))
  puts "Copy all docs json to javascript Done"
end


desc "Copy JSON file include subTask [copy_json_js, copy_index_json]"
task :copy_json => [:copy_json_js, :copy_index_json, :copy_credits] do
  puts "Copy JSON Done"
end

desc "Copy icons file to website"
task :copy_icons do
  FileUtils.rm_rf(Dir.glob(icons_target_path+ "*"))
  FileUtils.cp_r(icons_source_path + ".", icons_target_path)
end


desc "Copy assets file to website"
task :copy_asset do
  # remove sass
  # FileUtils.rm_rf(Dir.glob(sass_path+ "*"))
  # copy sass
  # FileUtils.cp_r(stylesheets_path + ".", sass_path)

  # remove image
  FileUtils.rm_rf(Dir.glob(image_target_path+ "*"))
  # copy image
  FileUtils.cp_r(docs_image_path + ".", image_target_path)
  FileUtils.cp_r("#{devdocs_path}/public/images/.", image_target_path)
end


desc "update all static files"
task :copy_all => [:copy_asset, :copy_icons, :copy_json, :generate_html] do
  Rake::Task[:copy_html].invoke("grunt|backbone|underscore|bower")
end
