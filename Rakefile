#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'json'
require 'nokogiri'
require 'logger'
require 'thread'

require "tty-progressbar"

require './lib/string'


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

$docs_json_path = "#{json_target_path}docs.json"
$debugTestDocs = "git|grunt|backbone|underscore|bower|typescript"


# github pages supported
$fix_link_regex = /(?=(?:(?!(\/|^)index).)*)((\/|^)index)?(?=#|$)/
# https://regex101.com/r/gZ0mK1/1

$alldocs = {}


def del_target(target)
  if Dir[target] != nil
    FileUtils.rm_rf(target)
  end
end

def get_type(slug)
  docs = $docs || ($docs = JSON.parse( IO.read($docs_json_path)))
  item = docs.select{ |item| item["slug"] == slug }
  item[0] && item[0]["type"]
end

def get_doc(slug)
  docs = $docs || ($docs = JSON.parse( IO.read($docs_json_path)))
  item = docs.select{ |item| item["slug"] == slug }
  begin
    item[0]
  rescue Exception => e
     raise "You need to run copy_json task first."
  end
  # item[0]
end

def get_link_title(slug, path)
  file = $alldocs[slug] || get_json_content('devdocs/public/docs/'+ slug +'/index.json')
  unless defined? $alldocs[slug]
    $alldocs[slug] = file
  end
  item = file["entries"].select{ |item| item["path"] == path }
  (item && item[0] && item[0]["name"]) || ""
end

def get_title(doc, slug, path, view_path, slugtitle)
  # puts slug, view_path
  scrantitle = pagetitle = nil
  pagetitle = get_link_title(slug, view_path)
  if pagetitle.blank?
    pagetitle = get_link_title(slug, view_path + '/')
    if pagetitle.blank?
      pagetitle = get_link_title(slug, view_path + '/index')
    end
  end
  begin
    scrantitle = doc.css('h1 > text()').text.blank? ? doc.css('h1') && doc.css('h1').first && doc.css('h1').first.text : doc.css('h1 > text()').text
  rescue => exception
    scrantitle = pagetitle
  end
  title = !(path =~ /docs-cache\/([\w~.]+)\/index\.html/) ? (!pagetitle.blank? ? pagetitle : scrantitle): ""
  if title.blank? 
    title = slugtitle + " documentation"
  else
    title = title + " - " + slugtitle
  end  
  title
end

def get_description(doc, slug, path, slugtitle)
  if Regexp.new(Regexp.quote("docs-cache\/#{slug}\/index\.html") + "$") =~ path # #{slug}
    slugtitle + " documentation"
  else
    doc.css('p') && doc.css('p').first && doc.css('p').first.text
  end
end

def fix_doc_link(html, path, slug)
  # puts path
  doc = Nokogiri::HTML(html)
  # fix link
  # doc.css("a").each do |link|
  #   if(link.attributes["href"])
  #     href = link.attributes["href"].value
  #     if(!(/^http(s)?/ =~ href))
  #       if(/^([^#]|\.\.\/)/ =~ href)
  #         if(!(/\w+\/index\.html/ =~path.sub(Regexp.new("{#docs_generate_target}"), ""))) #f
  #           href = "../" + href
  #         end
  #       end
  #       href = href.sub($fix_link_regex, (href[0,1] == "#" ? "" : "/"))
  #       if /api/=~ href && slug == "bower"
  #         href = href.sub(/api\//, "")
  #       end
  #       # if (/#/ =~ href)
  #       #   href = href.gsub(/(\/[\w-\.]+)#/, '\1/#')
  #       # elsif (!(/\.html$/ =~href))
  #       #   href = href + '/'
  #       # end
  #       link.attributes["href"].value = href
  #     else
  #       link.set_attribute('target', '_blank')
  #     end
  #   end
  # end
  slug = /docs-cache\/([\w~.]+)/.match(path)[1]
  view_path = /docs-cache\/[\w~.]+\/([\s\S]*?)?((\/\bindex\b)?\.html)$/.match(path)[1]
  # view_path = view_path.insert(-1, "/") if view_path[-1, 1] != "/"
  # puts "view_path: " + view_path
  begin  
    cdoc = get_doc(slug)
    slugtitle = cdoc["name"]  + (cdoc["version"] ? " " + cdoc["version"] : "")
    title = get_title(doc, slug, path, view_path, slugtitle)
    description = get_description(doc, slug, path, slugtitle)
    robj = {}
    robj[:text] = doc.css('body').inner_html
    robj[:title] = "\"#{title.enco}\""
    robj[:slug] = slug
    robj[:slugtitle] = slugtitle
    robj[:description] = "\"#{!description.nil? ? description.enco : title.enco}\""
    # robj[:permalink] = 
    robj[:isindex] = Regexp.new("([^\/]+)\/index\.html$") =~ path # #{slug}
    small_words = %w(a an as but by en in of the to v v. via vs vs. - _)
    begin
      scrantitle = doc.css('h1 > text()').text.blank? ? doc.css('h1') && doc.css('h1').first && doc.css('h1').first.text : doc.css('h1 > text()').text
    rescue => exception
      scrantitle = title
    end
    keywords = ((scrantitle.nil? ? "" : scrantitle) +" "+title).strip.downcase.split(/[\/\.\s\(\)\d,@:-_`"]+/).push(slug).uniq().reject { |c| c.empty? || c.is_i? || small_words.include?(c) }.join(", ").strip_html.strip
    robj[:keywords] = "\"#{keywords.enco}\""
    robj 
  rescue StandardError => e
    puts slug + " doc catch error: "   
    puts "on path: " + path
    puts "-----------"
    puts e
  end
end

def handle_file(target)
  # handle file
  slug = /docs-cache\/(\w+)/.match(target)[1] # doc name
  file = IO.read(target)
  doc = fix_doc_link(file, target, slug) # fix link
  type = get_type(doc[:slug])
  openfile = open(target, 'w') do |page|
    page.puts "---"
    page.puts "layout: docs"
    page.puts "title: #{doc[:title]}"
    page.puts "description: #{doc[:description]}"
    page.puts "keywords: #{doc[:keywords]}"
    page.puts "slug: #{doc[:slug]}"
    page.puts "slugtitle: #{doc[:slugtitle]}"
    page.puts "type: #{type}"
    # page.puts "permalink: " + (doc[:isindex] ?  "/:path.html" : "/:path")
    page.puts "---\n"
    page << "{% oopsraw %}\n"
    page << doc[:text]
    page << "{% endoopsraw %}"
  end
end

def generate_html(slug, source_path, target_path)
  files = Dir.glob(source_path + "**/*.html")
  bar = TTY::ProgressBar.new("%-12s : [:bar] :percent " % slug , width: 100, head: '>', total: files.size)
  files.each do |source|
      target = source.sub(/^#{source_path}/, target_path)
      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.copy(source, target)
      handle_file(target)
      bar.advance(1)
  end
end

def copy_html(source_path, target_path, names=true)
  if names
    Dir[source_path + "*"].each do |x|
      if names.kind_of?(Array)
        matchs = Regexp.new("(" + names.join("|") + ")$" ).match(x)
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

def get_json_content(target)
  file = JSON.parse(IO.read(target))
  # entries = file["entries"]
  # $logger.info("+ " + target)
  # entries.map! { |item|
  #   item["path"] = item["path"]
  #   .sub($fix_link_regex, '/')
  #   item
  # }
  file
end


def json_handle(target)
  puts target
  file = get_json_content(target)
  slug = /([\w~.]+)\.json/.match(target)[1]

  $alldocs[slug] = file  #cache for title generate

  openfile = open(target, 'w') do |page|
    page << "app.DOC = "
    page << get_doc(slug).to_json
    page <<";\napp.INDEXDOC = "
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

desc "genonly docs html"
task :genonly do |t, args|
  queue = Array.new
  Dir.glob("#{docs_path}/*") { |dir|
    dir.gsub!("#{docs_path}/",'')
    queue.push dir
  }
  # puts queue.sort()
  IO.write('.genonly', queue.sort().join("\n"))
end




desc "Generate docs html"
task :generate_html, :slug do |t, args|
  args.with_defaults(:slug=> false)
  slug = args[:slug]
  # puts slug
  threads = []
  queue = Queue.new
  history = false
  if slug
    slug.split(' ').each do |doc|
      doc = doc.gsub('@','~') # replace version spliter
      queue.push(doc)
    end
    
    # slug.split(' ').each do |doc|
    #   doc.gsub!('@','~') # replace version spliter
    #   puts doc + 'haha'
    #   del_target(docs_generate_target + doc + '/')
    #   generate_html(docs_path + doc + '/', docs_generate_target+ doc + '/')
    # end
  else
    if !File.exist?('.history')
      File.new('.history', "w").close
    end

    history = true
    historyFile = IO.read('.history')
    historys = historyFile.split("\n")
    # del_target(docs_generate_target)

    ignore = IO.read('.genonly')
    ignore = ignore.split("\n")

    Dir.glob("#{docs_path}/*") { |dir|
      dir.gsub!("#{docs_path}/",'')
      unless !ignore.include?(dir)
        queue.push dir
      end
    }
  end



  until queue.empty?
    doc = queue.pop(true) rescue nil
    if history
      if !(historys.include?(doc))
        del_target(docs_generate_target + doc + '/')
        generate_html(doc, docs_path + doc + '/', docs_generate_target+ doc + '/')
        # write history  
        File.open('.history', 'a') do |file|
          file.puts doc      
        end
      end
    else
      del_target(docs_generate_target + doc + '/')
      generate_html(doc, docs_path + doc + '/', docs_generate_target+ doc + '/')
    end
  end
  # 2.times do
  #   threads<<Thread.new do

  #   end
  # end
  # threads.each{|t| t.join}
end

task :sorthistory do |t, args|
  historys = IO.readlines('.history')
  historyFile = File.open('.history', 'w')
  historys.sort!.each do |item|
    historyFile.puts item
  end
  historyFile.close
end

desc "Copy docs html to website, if debug param is set, only copy a part of docs"
task :copy_html, :names do |t, args|
  args.with_defaults(:names=> true)
  names = args[:names]
  del_target(docs_target_path)
  if ["true", "false", true, false].include? names
    copy_html(docs_generate_target, docs_target_path, (names == "true" || names == true))
  else
    if names.is_a?(String) && names.match(/(\w+\\s?)*?/)
      names = names.split(" ")
      copy_html(docs_generate_target, docs_target_path, names)
    end
  end
end


desc "Generate html and copy"
task :gen_copy => [:generate_html, :copy_html] do
end


desc "Copy docs.json to website"
task :copy_index_json do
  # use meta.json is better
  filename = "docs.json"
  genonly = IO.read('.genonly')
  genonly = genonly.split("\n")
  data = []
  del_target(json_target_path + filename)
  genonly.each do |slug|
    meta_path = docs_path + slug + '/meta.json'
    next unless File.exist?(meta_path)
    data << JSON.parse(IO.read(meta_path))
  end

  IO.write(json_target_path + filename, data.to_json)
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
task :copy_json => [:copy_index_json, :copy_json_js, :copy_credits] do
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



desc "copy all html files, in order to pre-release"
task :copy_allhtml do
  Rake::Task[:copy_html].invoke(false)
end


desc "update all static files"
task :copy_all => [:copy_asset, :copy_icons, :copy_json] do
  # Rake::Task[:copy_html].invoke("html|jquery|css")
  # Rake::Task[:copy_test].invoke()
end



desc "generate html test"
task :generate_test  do # => [:copy_json_js]
  Rake::Task[:generate_html].invoke("spring_boot sequelize")
end


desc "copy html static files for test"
task :copy_test do
  Rake::Task[:copy_html].invoke("spring_boot sequelize")
end

desc "default"
task :default do
  system "echo \"DONE, Bye~\""
  system "exit 0"
end


desc "travis ci init devdocs"
task :devdocsci do
  cd "#{devdocs_path}" do 
    Bundler.with_clean_env {
      system "bundle exec thor docs:download --default"
    }
  end
end