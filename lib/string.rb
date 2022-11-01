require "cgi"

class String
    def is_i?
       /\A[-+]?\d+\z/ === self
    end
    def enco
      # self.encode(:xml => :attr)
      # gsub("\"","&quot;")
        # .gsub("\:","&#58;")
        # .gsub("\\","&#124;")
        # .gsub("\'","&#39;")
        # .gsub("\*", "&#42;")
        # .gsub("\$", "&#42;")
        # .gsub("\^", "&#42;")
      self
        .gsub(/[\@\^\$\/\&\*\:\>\<\=\\\"\']/) { |m| '&#' + m.ord.to_s + ';'}
    end

    def blank?
      respond_to?(:empty?) ? !!empty? : !self
    end

    def strip_html
      input = self
      empty = ''.freeze
      input.to_s.gsub(/<script.*?<\/script>/m, empty).gsub(/<!--.*?-->/m, empty).gsub(/<style.*?<\/style>/m, empty).gsub(/<.*?>/m, empty)
    end

    def condense_spaces
      input = self
      input.gsub(/\s{2,}/, ' ')
    end

    def truncate(length)
      input = self
      if input.length > length && input[0..(length-1)] =~ /(.+)\b.+$/im
        $1.strip + ' &hellip;'
      else
        input
      end
    end
    # covert string to title case 
    def titlecase
      input = self
      input.gsub(/\w+/) { |word| word.capitalize }
    end
    
end